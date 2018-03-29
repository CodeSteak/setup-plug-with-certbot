defmodule Webserver.Router do
  use Plug.Router
  plug(Plug.Logger, log: :debug)

  plug(
    Plug.Static,
    at: "/",
    from: Application.fetch_env!(:webserver, :www_dir),
    gzip: false,
    only_matching: ~w(.well-known)
  )

  if Application.fetch_env!(:webserver, :use_https) do
    plug(Plug.SSL)
  end

  plug(:match)
  plug(:dispatch)

  get(
    "/",
    do:
      send_resp(
        conn,
        200,
        "Welcome! #{ip_version(conn)} " <> (Time.utc_now() |> Time.to_string())
      )
  )

  get("/coffee", do: send_resp(conn, 418, "Only tea, sry!"))

  get("/hello", do: send_resp(conn, 200, "world!"))

  match(_, do: send_resp(conn, 404, "Oops!"))

  defp ip_version(conn) do
    case conn.peer do
      {{_, _, _, _}, _} ->
        "IPV4"

      {{0, 0, 0, 0, _, _, _, _}, _} ->
        "IP4 OR IPV6"

      {{_, _, _, _, _, _, _, _}, _} ->
        "IPV6"
    end
  end
end
