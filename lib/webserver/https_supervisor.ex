defmodule Webserver.HTTPS.Supervisor do
  use Supervisor

  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts},
      restart: :permanent,
      shutdown: 5000,
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    certbot_env = setup_cfg()
    children = https_worker(certbot_env)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp setup_cfg() do
    certs_dir = Application.fetch_env!(:webserver, :certs_dir)
    www_dir = Application.fetch_env!(:webserver, :www_dir)
    utils_dir = Application.fetch_env!(:webserver, :utils_dir)

    https_opts = Application.fetch_env!(:webserver, :https_opts)
    keyfile = Keyword.get(https_opts, :keyfile)

    File.mkdir_p!(certs_dir)
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

    certbot_cfg = Application.fetch_env!(:webserver, :certbot)

    certbot_env_args =
      [
        "--non-interactive",
        "--config-dir",
        Keyword.get(certbot_cfg, :config_dir),
        "--work-dir",
        Keyword.get(certbot_cfg, :work_dir),
        "--logs-dir",
        Keyword.get(certbot_cfg, :logs_dir)
      ] ++
        if Keyword.get(certbot_cfg, :agree_tos) == :yes do
          ["--agree-tos"]
        else
          IO.warn("You may want agree letsencrypt tos in config.exs")
        end ++
        if Keyword.get(certbot_cfg, :testing) do
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
    utils_dir = Application.fetch_env!(:webserver, :utils_dir)
    certbot_cfg = Application.fetch_env!(:webserver, :certbot)
    www_dir = Application.fetch_env!(:webserver, :www_dir)

    File.write!(Path.join(utils_dir, "local-certbot.sh"), """
    #!/bin/sh
    certbot #{certbot_env_args |> Enum.map(fn x -> "'#{x}'" end) |> Enum.join(" ")} $*
    """)

    certbot_args =
      [
        "certonly",
        "-m",
        Keyword.get(certbot_cfg, :email),
        "--webroot",
        "-w",
        www_dir,
        "-d",
        Enum.join(Keyword.get(certbot_cfg, :domains), ",")
      ] ++
        if Keyword.get(certbot_cfg, :eff_email) do
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

  defp https_worker(certbot_env) do
    [
      {Plug.Adapters.Cowboy2,
       scheme: :https,
       plug: Webserver.Router,
       options: Application.fetch_env!(:webserver, :https_opts)},
      {Webserver.CertsRenewer, certbot_env}
    ]
  end
end
