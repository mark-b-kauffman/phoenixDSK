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

  @doc """
  From router: get "/users", UserController, :index
  See http://www.phoenixframework.org/docs/adding-pages
  The core of this action is render conn, "index.html". This tells Phoenix
  to find a template called index.html.eex and render it. Phoenix will look
  for the template in a directory named after our controller,
  so web/templates/user.
  """
  def index(conn, _params) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, userList} = Lms.all(fqdn, Learn.User) # List of structs
    {:ok, intentionallyUnused, dskMap } = LearnRestClient.get_data_sources(fqdn)
    render conn, "index.html", userList: userList, dskMap: dskMap, fqdn: fqdn
  end

  @doc """
  From router: get "/users/:userName", UserController, :show
  """
  def show(conn, %{"userName" => userName}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, user} = Lms.get(fqdn, Learn.User, userName) # user as struct
    {:ok, intentionallyUnused, dskMap} = LearnRestClient.get_data_sources(fqdn)
    # dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
    # dskList = [%{"id" => "_2_1", "externalId" => "SYSTEM"}, %{"id" => "_1_1", "externalId" => "INTERNAL"}]
    # here we need a util method that takes the dskMap and returns a list in the above form....
    # What do you know, Elixir lets us do this witha one-liner! No need for a util method!
    dskList = Enum.map(dskMap, fn {k, v} -> %{"id" => k, "externalId"=>v["externalId"] } end)
    render conn, "show.html", userName: userName, user: user, dskMap: dskMap, dskList: dskList
  end

  @doc """
  From router: post "/users/:userName", UserController, :update
  """
  def update(conn, %{"userName" => userName, "session" => session}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, user} = LearnRestClient.get_user_with_userName(fqdn, userName)
    # Update the user in the LMS with this line.
    Logger.info "DSK value selected #{session["selected_dsk"]}"
    Logger.info "'available' value selected #{session["selected_avail"]}"
    new_avail = session["selected_avail"]
    new_dsk = session["selected_dsk"]
    Logger.info user["id"]
    # Create a new user with the selected values.
    # Elixir values are immutable so have to create a new one.
    newUser = %{user | "availability" => %{"available" => "#{new_avail}"}, "dataSourceId" => "#{new_dsk}"}
    # Call the REST APIs to update the user.
    {:ok} = LearnRestClient.update_user_with_userName(fqdn, userName, newUser)
    # Now show.
    show(conn, %{"userName" => userName})
  end #update

end
