defmodule PhoenixDSK.UserController do
  use PhoenixDSK.Web, :controller
  require Logger
  alias PhoenixDSK.Lms, as: Lms

  @doc """
  Notes:
  Regarding Availability and Row Status
    %{"availability" => %{"available" => "No"}, ... }
    %{"availability" => %{"available" => "Yes"}, ... }
    %{"availability" => %{"available" => "Disabled"}, ... }

  Regarding the User data structure
  iex(3)> {:ok, user} = PhoenixDSK.Lms.get(fqdn, Learn.User, "mkauffman-student")
    {:ok,
      %Learn.User{availability: %{"available" => "Yes"},
      contact: %{"email" => "markkauffman2000@gmail.com"}, dataSourceId: "_2_1",
      externalId: "mkauffman-student", id: "_92_1",
      name: %{"family" => "Kauffman", "given" => "Mark (Student)",
      "title" => "student"}, userName: "mkauffman-student"}}

  Regarding the dskMap
  iex(4)> dskMap = LearnRestClient.get(fqdnAtom, "dskMap")
    %{"_10_1" => %{"externalId" => "MicrosoftAzureAD", "id" => "_10_1"},
    "_17_1" => %{"description" => "Data source for Google",
      "externalId" => "DS_GG", "id" => "_17_1"},
    "_19_1" => %{"description" => "Accounts from MH test IdP",
      "externalId" => "mh_shib", "id" => "_19_1"},
    "_1_1" => %{"description" => "Internal data source used for associating records that are created for use by the Bb system.",
      "externalId" => "INTERNAL", "id" => "_1_1"}, ... }
  """

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
    {:ok, user} = Lms.get(fqdn, Learn.User, userName) # user as struct
    {:ok, unused} = LearnRestClient.get_data_sources(fqdn)
    dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
    dskList = [%{"id" => "_2_1", "externalId" => "SYSTEM"}, %{"id" => "_1_1", "externalId" => "INTERNAL"}]
    # here we need a util method that takes the dskMap and returns a list in the above form....
    render conn, "show.html", user: user, dskMap: dskMap, dskList: dskList
  end

  def update(conn, %{"userName" => userName, "session" => session}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, user} = Lms.get(fqdn, Learn.User, userName)
    # Update the user in the LMS with this line.
    Logger.info "You selected #{session["selected_dsk"]}"
    Logger.info "You selected #{session["selected_avail"]}"
    # Now show.
    show(conn, %{"userName" => userName})
  end #update

end
