defmodule PhoenixDSK.Lms do

  # Puropse: Abstraction, Repo-like methods for accessing Blackboard Learn
  # Instead of a database, we have the Blackboard Learn LMS.

  @doc """
  Get all the dataSources as a list of Learn.DSK structs
  This behavior is analogous to a Repo.
  2017.04.18 - Can't generalize here because we are calling the particular
  get method for the given structure type. Hence there is an all method for
  Learn.Dsk, and another all method for Learn.User, etc.
  """
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
  Get a user with the given userName. userName is in the format mkauffman
  This behavior is analogous to a Repo.
  """
  def get(fqdn, Learn.User, userName) do
    {:ok, userResponse} = LearnRestClient.get_user_with_userName(fqdn, userName)
    user = LearnRestUtil.to_struct(Learn.User, userResponse)
    {:ok, user}
  end

end
