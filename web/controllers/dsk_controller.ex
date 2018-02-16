defmodule PhoenixDSK.DskController do
  use PhoenixDSK.Web, :controller
  alias PhoenixDSK.Lms, as: Lms
  @doc """
  See http://www.phoenixframework.org/docs/adding-pages
  The core of this action is render conn, "index.html". This tells Phoenix
  to find a template called index.html.eex and render it. Phoenix will look
  for the template in a directory named after our controller,
  so web/templates/dsk.
  """
  def index(conn, _params) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, dskList} = Lms.all(fqdn, Learn.Dsk, "allpages")
    render conn, "index.html", dskList: dskList, fqdn: fqdn
  end

end
