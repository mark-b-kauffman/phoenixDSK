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
      # dsk_list = Enum.map(dskMap, fn {k, v} -> %{"id" => k, "externalId"=>v["externalId"] } end)
      # Now that we do the following we have to change how the template accesses the data.
      # The keys are no longer strings so we have to use the . notation.
      {:ok, dsk_list} = Lms.all(fqdn, Learn.Dsk, "allpages")
      # dsk_list is a list of maps
      # [ %Learn.Dsk{description: "blah.", externalId: "INTERNAL", id: "_1_1" }, %Learn.Dsk ... ]
      mapout = %{}
      dsk_map = LearnRestUtil.listofstructs_to_mapofstructs( dsk_list, mapout, :id )
      #dsk_map is a map of structs


      {:ok, membership} = Lms.get(fqdn, Learn.Membership, courseId, userName)
      render conn, "show.html", courseId: courseId, course: course, userName: userName, user: user, membership: membership, dskMap: dsk_map, dskList: dsk_list
  end

  @doc """
  From router: post "/membership/:courseId/:userName", MembershipController, :update
  """
  def update(conn, %{"courseId" => courseId, "userName" => userName, "session" => session}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, course} = LearnRestClient.get_course_with_courseId(fqdn, courseId)
    {:ok, membership} = LearnRestClient.get_membership(fqdn, courseId, userName)
    # Update the membership in the LMS with this line.
    Logger.info "DSK value selected #{session["selected_dsk"]}"
    Logger.info "'available' value selected #{session["selected_avail"]}"

    # Why do we need newCourse before we create the thing we update?
    # What was the reasoning behind the hidden inputs? Ensure valid post?
    Logger.info "newCourse:#{session["newCourse"]}"
    Logger.info "courseId:#{courseId}"
    newCourse = session["newCourse"]
    # if not(String.equivalent?(newCourse, courseId)) do # TODO: REMOVE
       courseId = newCourse
    # end
    newUser = session["newUser"]
    # if not(String.equivalent?(newUser, userName)) do # TODO: REMOVE
       userName = newUser
    # end

    new_avail = session["selected_avail"]
    new_dsk = session["selected_dsk"]
    Logger.info course["id"]
    # Create a new membership with the selected values.
    # Elixir values are immutable so create a new membership
    temp = %{membership | "availability" => %{"available" => "#{new_avail}"}, "dataSourceId" => "#{new_dsk}"}
    newMembership = Map.delete(temp, "created")
    # Call the REST APIs to update the membership.
    {:ok} = LearnRestClient.update_membership(fqdn, courseId, userName, newMembership)
    # Now show.
    show(conn, %{"courseId" => courseId, "userName" => userName})
  end #update


end
