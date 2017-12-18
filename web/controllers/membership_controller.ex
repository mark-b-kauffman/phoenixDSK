defmodule PhoenixDSK.MembershipController do
  # For managing one membership. 2017.12.12
  # TODO: Modify the following to manage one membership.

  use PhoenixDSK.Web, :controller
  require Logger
  alias PhoenixDSK.Lms, as: Lms

  @doc """
  Notes:
  Regarding Availability and Row Status
    %{"availability" => %{"available" => "No"}, ... }
    %{"availability" => %{"available" => "Yes"}, ... }
    %{"availability" => %{"available" => "Disabled"}, ... }

  Regarding the Course data structure
  iex(3)> {:ok, course} = PhoenixDSK.Lms.get(fqdn, Learn.Course, "mbk-course-a")
  {:ok,
   %Learn.Course{availability: %{"available" => "Yes",
      "duration" => %{"type" => "Continuous"}}, courseId: "mbk-course-a",
    dataSourceId: "_2_1", description: "Test course A.",
    externalId: "mbk-course-a", id: "_3_1", name: "mbk-course-a",
    organization: false}}

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
  def init() do
    # Now the compiler won't complain about the documentation above being re-defiend for the following.
  end

  @doc """
  From router: get "/membership/:courseId/:userName", MembershipController, :show
  """
  def show(conn, %{"courseId" => courseId, "userName" => userName }) do
      fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
      {:ok, course} = Lms.get(fqdn, Learn.Course, courseId) # course as struct
      {:ok, user} = Lms.get(fqdn, Learn.User, userName)
      {:ok, intentionallyUnused, dskMap} = LearnRestClient.get_data_sources(fqdn)
      # dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
      # dskList = [%{"id" => "_2_1", "externalId" => "SYSTEM"}, %{"id" => "_1_1", "externalId" => "INTERNAL"}]
      # here we need a util method that takes the dskMap and returns a list in the above form....
      # What do you know, Elixir lets us do this witha one-liner! No need for a util method!
      dsk_list = Enum.map(dskMap, fn {k, v} -> %{"id" => k, "externalId"=>v["externalId"] } end)

      {:ok, membership} = Lms.get(fqdn, Learn.Membership, courseId, userName)
      render conn, "show.html", courseId: courseId, course: course, userName: userName, user: user, membership: membership, dskMap: dskMap, dskList: dsk_list
  end

end
