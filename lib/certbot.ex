defmodule Certbot do
  use Supervisor

  def child_spec(args, opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [args, opts]},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
    }
  end

  def start_link(args, opts \\ []) do
    Supervisor.start_link(__MODULE__, args, opts)
  end

  def init(args) do
    innerworker = Keyword.get(args, :worker, [])
    IO.puts("init #{__MODULE__}")
    certbot_env = setup_cfg()
    children = worker(certbot_env) ++ innerworker

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp setup_cfg() do
    www_dir = Application.fetch_env!(:certbot, :www_dir)
    utils_dir = Application.fetch_env!(:certbot, :utils_dir)

    domains = Application.fetch_env!(:certbot, :domains)

    keyfile =
      Path.join([Application.fetch_env!(:certbot, :config_dir), "live", List.first(domains)])

    File.mkdir_p!(www_dir)
    File.mkdir_p!(utils_dir)

    case System.cmd("which", ["certbot"]) do
      {_, 0} ->
        :ok

      _ ->
        throw("""
        certbot was not found!,
        please install certbot.
        [Or it is not in PATH]
        https://certbot.eff.org/
        """)
    end

    certbot_env_args =
      [
        "--non-interactive",
        "--config-dir",
        Application.fetch_env!(:certbot, :config_dir),
        "--work-dir",
        Application.fetch_env!(:certbot, :work_dir),
        "--logs-dir",
        Application.fetch_env!(:certbot, :logs_dir)
      ] ++
        if Application.fetch_env!(:certbot, :agree_tos) == :yes do
          ["--agree-tos"]
        else
          IO.warn("You may want agree letsencrypt tos in config.exs")
        end ++
        if Application.fetch_env!(:certbot, :testing) do
          IO.puts("running with testing server")
          ["--server", "https://acme-staging.api.letsencrypt.org/directory"]
        else
          []
        end

    if(!File.exists?(keyfile)) do
      IO.puts("== START Setting up cert")
      setup_cert(certbot_env_args)
      IO.puts("== END   Setting up cert")
    end

    certbot_env_args
  end

  def setup_cert(certbot_env_args) do
    www_dir = Application.fetch_env!(:certbot, :www_dir)
    utils_dir = Application.fetch_env!(:certbot, :utils_dir)

    File.write!(Path.join(utils_dir, "local-certbot.sh"), """
    #!/bin/sh
    certbot #{certbot_env_args |> Enum.map(fn x -> "'#{x}'" end) |> Enum.join(" ")} $*
    """)

    certbot_args =
      [
        "certonly",
        "-m",
        Application.fetch_env!(:certbot, :email),
        "--webroot",
        "-w",
        www_dir,
        "-d",
        Enum.join(Application.fetch_env!(:certbot, :domains), ",")
      ] ++
        if Application.fetch_env!(:certbot, :eff_email) do
          ["--eff-email"]
        else
          ["--no-eff-email"]
        end

    case System.cmd("certbot", certbot_env_args ++ certbot_args) do
      {info, 0} ->
        IO.puts(info)
        IO.puts("Certificates Generated")

      {info, i} ->
        IO.puts(info)
        throw("Certificates not Generated. Exit Code #{i}")
    end
  end

  defp worker(certbot_env) do
    [
      {Certbot.CertsRenewer, certbot_env}
    ]
  end
end
