defmodule PhoenixDSK.UserController do
  use PhoenixDSK.Web, :controller
  alias PhoenixDSK.Lms, as: Lms

  # See http://www.phoenixframework.org/docs/adding-pages
  # The core of this action is render conn, "index.html". This tells Phoenix
  # to find a template called index.html.eex and render it. Phoenix will look
  # for the template in a directory named after our controller,
  # so web/templates/user.
  def index(conn, _params) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, userList} = Lms.all(fqdn, Learn.User)
    {:ok, unused} = LearnRestClient.get_data_sources(fqdn)
    dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
    render conn, "index.html", userList: userList, dskMap: dskMap, fqdn: fqdn
  end

  def show(conn, %{"userName" => userName}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, user} = Lms.get(fqdn, Learn.User, userName)
    {:ok, unused} = LearnRestClient.get_data_sources(fqdn)
    dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
    render conn, "show.html", user: user, dskMap: dskMap
  end

  def update(conn, %{"userName" => userName}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, user} = Lms.get(fqdn, Learn.User, userName)
    {:ok, unused} = LearnRestClient.get_data_sources(fqdn)
    dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
    render conn, "show.html", user: user, dskMap: dskMap
  end #update

end
