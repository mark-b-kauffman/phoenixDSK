defmodule PhoenixDSK.PageController do
  use PhoenixDSK.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
