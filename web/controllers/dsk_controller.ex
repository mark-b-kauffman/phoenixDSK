defmodule PhoenixDSK.DskController do
  use PhoenixDSK.Web, :controller
  alias PhoenixDSK.Depot, as: Depot

  # See http://www.phoenixframework.org/docs/adding-pages
  # The core of this action is render conn, "index.html". This tells Phoenix
  # to find a template called index.html.eex and render it. Phoenix will look
  # for the template in a directory named after our controller,
  # so web/templates/user.
  def index(conn, _params) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, dskList} = Depot.all(fqdn, Learn.Dsk)
    render conn, "index.html", dskList: dskList, fqdn: fqdn
  end

end
