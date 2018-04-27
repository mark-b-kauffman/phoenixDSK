# Credit to https://github.com/paulfedory/how_to_watch_tv/blob/master/web/basic_auth.ex
# https://medium.com/@paulfedory/basic-authentication-in-your-phoenix-app-fa24e57baa8
defmodule BasicAuth do
  import Plug.Conn
  require Logger

  @realm "Basic realm=\"phoenixDSK\""

  def init(opts), do: opts

  # get_req_header(conn, key) Returns the values of the request header specified by key
  # values is plural, hence a list. The values of the authorization header looks like:
  # ["Basic dXNlcjM6c2VjcmV0Mw=="]

  def call(conn, correct_auth_details) do
    Logger.info IO.inspect(get_req_header(conn, "authorization"), [])
    case get_req_header(conn, "authorization") do
      ["Basic " <> auth] -> verify(conn, auth, correct_auth_details)
      _                  -> unauthorized(conn)
    end
  end

  defp verify(conn, attempted_auth, [username: username, password: password]) do
    case encode(username, password) do
      ^attempted_auth -> conn
      _               -> unauthorized(conn)
    end
  end

  defp encode(username, password), do: Base.encode64(username <> ":" <> password)

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", @realm)
    |> send_resp(401, "unauthorized")
    |> halt()
  end
end
