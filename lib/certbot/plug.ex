defmodule Certbot.Plug do
  use Plug.Router

  if Application.fetch_env(:certbot, :domains) != :error do
    plug(
      Plug.Static,
      at: "/",
      from: Application.fetch_env!(:certbot, :www_dir),
      gzip: false,
      only_matching: ~w(.well-known)
    )

    plug(:match)
  else
    plug(:match)

    match("/.well-known/*_rest") do
      IO.warn("Bad Cerbot Config!")
      send_resp(conn, 500, "See Logs")
    end
  end

  match(_) do
    conn
  end
end
