defmodule PhoenixDSK.HelloController do
  use PhoenixDSK.Web, :controller
  # See http://www.phoenixframework.org/docs/adding-pages
  # The core of this action is render conn, "index.html". This tells Phoenix
  # to find a template called index.html.eex and render it. Phoenix will look
  # for the template in a directory named after our controller,
  # so web/templates/user.
  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, %{"userName" => userName}) do
    render conn, "show.html", userName: userName
  end

end
