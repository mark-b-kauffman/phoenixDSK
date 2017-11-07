defmodule PhoenixDSK.Lms do

  # Puropse: Abstraction, Repo-like methods for accessing Blackboard Learn
  # Instead of a database, we have the Blackboard Learn LMS.

  @doc """
  Get all the dataSources as a list of Learn.DSK structs
  This behavior is analogous to a Repo.
  2017.04.18 - Can't generalize here because we are calling the particular
  get method for the given structure type. Hence there is an all method for
  Learn.Dsk, and another all method for Learn.User, etc.
  Example Usage:
    iex(1)> fqdn = "bd-partner-a-original.blackboard.com"
      "bd-partner-a-original.blackboard.com"
    iex(2)> PhoenixDSK.Lms.all(fqdn,Learn.Dsk)
    {:ok,
    [%Learn.Dsk{description: "Internal data source used for associating records that are created for use by the Bb system.",
      externalId: "INTERNAL", id: "_1_1"},
      %Learn.Dsk{description: "System data source used for associating records that are created via web browser.",
      externalId: "SYSTEM", id: "_2_1"},...
  """

  require Logger

  def all(fqdn, Learn.Dsk) do
    {:ok, dskResponseMap, dskMapUnused} = LearnRestClient.get_data_sources(fqdn)
    {:ok, dskList} = LearnRestUtil.listofmaps_to_structs(Learn.Dsk,dskResponseMap["results"])
    {:ok, dskList}
  end

  @doc """
  Get all the users as a list of Learn.User structs
  This behavior is analogous to a Repo.
  """
  def all(fqdn, Learn.User) do
    {:ok, usersResponseMap} = LearnRestClient.get_users(fqdn)
    {:ok, userList} = LearnRestUtil.listofmaps_to_structs(Learn.User,usersResponseMap["results"])
    {:ok, userList}
  end

  @doc """
  Get all the courses as a list of Learn.User structs
  This behavior is analogous to a Repo.
  """
  def all(fqdn, Learn.Course) do
    {:ok, coursesResponseMap} = LearnRestClient.get_courses(fqdn)
    {:ok, courseList} = LearnRestUtil.listofmaps_to_structs(Learn.Course,coursesResponseMap["results"])
    {:ok, courseList}
  end

  @doc """
  Get a user with the given userName. userName is in the format mkauffman
  This behavior is analogous to a Repo.
  """
  def get(fqdn, Learn.User, userName) do
    {:ok, userResponse} = LearnRestClient.get_user_with_userName(fqdn, userName)
    user = LearnRestUtil.to_struct(Learn.User, userResponse)
    {:ok, user}
  end

  @doc """
  Get a course with the given courseName. courseId is in the format abc-123, no spaces!
  Learn does not allow spaces in a courseId.
  This behavior is analogous to a Repo.
  """
  def get(fqdn, Learn.Course, courseId) do
    {:ok, courseResponse} = LearnRestClient.get_course_with_courseId(fqdn, courseId)
    course = LearnRestUtil.to_struct(Learn.Course, courseResponse)
    {:ok, course}
  end

  @doc """
  Get the memberships for a given courseId. courseId is in the format abc-123, no spaces!
  Learn does not allow spaces in a courseId.
  """
  def get(fqdn, Learn.MembershipResults, courseId) do
    {:ok, membership_response} = LearnRestClient.get_memberships_for_courseId(fqdn, courseId)
    membership_results = LearnRestUtil.to_struct(Learn.MembershipResults, membership_response)
    Logger.info "Exit get Learn.Membership"
    {:ok, membership_results}
  end

  @doc """
  Get the memberships for a given courseId. courseId is in the format abc-123, no spaces!
  Learn does not allow spaces in a courseId.
  """
  def get(fqdn, Learn.MembershipResults, courseId, offset) do
    {:ok, membership_response} = LearnRestClient.get_memberships_for_courseId(fqdn, courseId, offset)
    membership_results = LearnRestUtil.to_struct(Learn.MembershipResults, membership_response)
    Logger.info "Exit get Learn.Membership"
    {:ok, membership_results}
  end

end
