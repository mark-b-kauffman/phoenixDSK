defmodule PhoenixDSK.CourseController do
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
  iex(3)> {:ok, course} = PhoenixDSK.Lms.get(fqdn, Learn.Course, "mkauffman-student")
    {:ok,
      %Learn.Course{availability: %{"available" => "Yes"},
      contact: %{"email" => "markkauffman2000@gmail.com"}, dataSourceId: "_2_1",
      externalId: "mkauffman-student", id: "_92_1",
      name: %{"family" => "Kauffman", "given" => "Mark (Student)",
      "title" => "student"}, courseName: "mkauffman-student"}}

  Regarding the dskMap
  Note that the LearnRestClient.get doesn't get all of the DSKs.
  We had to switch to {:ok, dskList} = Lms.all(fqdn, Learn.Dsk, "allpages")
  which returns the complete list of dsk structs, then convert that to a map.
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
  From router: get "/courses", CourseController, :index
  See http://www.phoenixframework.org/docs/adding-pages
  The core of this action is render conn, "index.html". This tells Phoenix
  to find a template called index.html.eex and render it. Phoenix will look
  for the template in a directory named after our controller,
  so web/templates/course.
  """
  def index(conn, _params) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, courseList} = Lms.all(fqdn, Learn.Course) # List of structs
    # {:ok, intentionallyUnused, dskMap } = LearnRestClient.get_data_sources(fqdn)
    {:ok, dskList} = Lms.all(fqdn, Learn.Dsk, "allpages")
    # dskList is a list of maps
    # [ %Learn.Dsk{description: "blah.", externalId: "INTERNAL", id: "_1_1" }, %Learn.Dsk ... ]
    mapout = %{}
    dskMap = LearnRestUtil.listofstructs_to_mapofstructs( dskList, mapout, :id )
    #dskMap is a map of structs
    render conn, "index.html", courseList: courseList, dskMap: dskMap, fqdn: fqdn
  end

  @doc """
  From router: get "/courses/:courseId", CourseController, :show
  """
  def show(conn, %{"courseId" => courseId}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, course} = Lms.get(fqdn, Learn.Course, courseId) # course as struct
    # {:ok, intentionallyUnused, dskMap} = LearnRestClient.get_data_sources(fqdn)
    # dskMap =  LearnRestClient.get(String.to_atom(fqdn), "dskMap")
    # dskList = [%{"id" => "_2_1", "externalId" => "SYSTEM"}, %{"id" => "_1_1", "externalId" => "INTERNAL"}]
    # here we need a util method that takes the dskMap and returns a list in the above form....
    # What do you know, Elixir lets us do this witha one-liner! No need for a util method!
    # dskList = Enum.map(dskMap, fn {k, v} -> %{"id" => k, "externalId"=>v["externalId"] } end)
    # Saving the above because it's how we first did this AND the on-liner is cool.

    # Now that we do the following we have to change how the template accesses the data.
    # The keys are no longer strings so we have to use the . notation.
    {:ok, dskList} = Lms.all(fqdn, Learn.Dsk, "allpages")
    # dskList is a list of maps
    # [ %Learn.Dsk{description: "blah.", externalId: "INTERNAL", id: "_1_1" }, %Learn.Dsk ... ]
    mapout = %{}
    dskMap = LearnRestUtil.listofstructs_to_mapofstructs( dskList, mapout, :id )
    #dskMap is a map of structs
    render conn, "show.html", courseId: courseId, course: course, dskMap: dskMap, dskList: dskList
  end

  def select(conn, %{"session" => session}) do
    newCourseId = session["newCourseId"]
    redirect conn, to: course_path(conn, :show, newCourseId )
  end

  @doc """
  From router: post "/courses/:courseId", CourseController, :update
  """
  def update(conn, %{"courseId" => courseId, "session" => session}) do
    fqdn = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
    {:ok, course} = LearnRestClient.get_course_with_courseId(fqdn, courseId)
    # Update the course in the LMS with this line.
    Logger.info "DSK value selected #{session["selected_dsk"]}"
    Logger.info "'available' value selected #{session["selected_avail"]}"
    Logger.info "newCourse:#{session["newCourse"]}"
    Logger.info "courseId:#{courseId}"
    newCourse = session["newCourse"]
    # if not(String.equivalent?(newCourse, courseId)) do # TODO: REMOVE
      courseId = newCourse
    # end
    new_avail = session["selected_avail"]
    new_dsk = session["selected_dsk"]
    Logger.info course["id"]
    # Create a new course with the selected values.
    # Elixir values are immutable so have to create a new one.
    newCourse = %{course | "availability" => %{"available" => "#{new_avail}"}, "dataSourceId" => "#{new_dsk}"}
    # Call the REST APIs to update the course.
    {:ok} = LearnRestClient.update_course_with_courseId(fqdn, courseId, newCourse)
    # Now show.
    show(conn, %{"courseId" => courseId})
  end #update

end
