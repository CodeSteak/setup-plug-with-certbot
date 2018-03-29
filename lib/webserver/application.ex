defmodule Webserver.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children =
      if Application.fetch_env!(:webserver, :use_https) do
        http_worker() ++ https_worker()
      else
        http_worker()
      end

    setup_cfg()
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Webserver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp setup_cfg() do
    www_dir = Application.fetch_env!(:webserver, :www_dir)
    File.mkdir_p!(www_dir)
  end

  defp http_worker() do
    [
      {Plug.Adapters.Cowboy2,
       scheme: :http,
       plug: Webserver.Router,
       options: Application.fetch_env!(:webserver, :http_opts)}
    ]
  end

  defp https_worker() do
    [{Webserver.HTTPS.Supervisor, []}]
  end
end
