# File: learnrestclient.ex
# Author: Mark Bykerk Kauffman
# Date : 2017.03
# 2017.03.24 MBK - moved appkey and appsecret to config/dev.exs.
# 2017.12.27 MBK - When we get an access token, we calculate and save the time it will expire.
# Then we check the time and refresh our access token on expiration in get_json_request_headers
defmodule LearnRestClient do
  require Logger
  # We want to be able to access these module constants outside of the module.
  # We define a key-value map with all of them. The appkey and secret are not valid.
  # Change them to be the app key and secret you get for your app from developer.blackboard.com.
  # 2017.03.24 MBK moved key and secret to config/dev.exs.
  @kv %{
        tokenendpoint: "/learn/api/public/v1/oauth2/token",
        dskendpoint: "/learn/api/public/v1/dataSources",
        usersendpoint: "/learn/api/public/v1/users",
        coursesendpoint: "/learn/api/public/v1/courses",
      }
  @doc """
  Return this module's Key/Value constant, kv.
  """
  def get_kv() do
    @kv
  end

  # SECTION I.
  # This section implements a Key/Value 'Bucket' as described at
  # http://elixir-lang.org/getting-started/mix-otp/agent.html
  #
  # Elixir is functional. Elixir functions do not maintain state.
  # Instead we need some type of process to do so. Agents provide
  # a simple wrapper around state.
  #
  # We're going to use the KV Bucket to maint state regarding our
  # hostname, the auth token for a particular host, and anything
  # that I can't think of at the moment that we'll need to
  # have 'knowledge' of the particular Learn server the code is 'talking'
  # to by making REST calls. The second section will implement the different
  # REST calls as functions to save the different modules making the REST calls
  # having to re-implement the code.

  @doc """
  Start the agent with the given 'name'. We can have many of these.
  name must be an atom. This Agent is wrapping an Elixir Map.

  """
  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: name)
  end

  @doc """
  To understand the code in this function,
  Agent.get(name,  &Map.get(&1, key))
  the following is helpful:
  iex> {:ok, agent} = Agent.start_link fn -> [] end
  {:ok, #PID<0.57.0>}
  << we wrapped a list >>
  iex> Agent.update(agent, fn list -> ["eggs" | list] end)
  :ok
  << passed in a function to add to the list >>
  iex> Agent.get(agent, fn list -> list end)
  ["eggs"]
  << passed in a function that returns the list >>
  iex> Agent.stop(agent)
  :ok
  Here we get the value speced by a key from the 'bucket' with the given name.
  name is an atom, key is a string. &1 represents the first paramater, a Map.
  """
  def get(name, key) do
    Agent.get(name,  &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket` with the given name.
  """
  def put(name, key, value) do
    Agent.update(name, &Map.put(&1, key, value))
  end

 # SECTION II. Everything specific to making REST calls to Learn.

 @doc """
 Set up a demo client.

 """
 def start_demo() do
   fqdn = "bd-partner-a-original.blackboard.com"
   fqdnAtom = String.to_atom(fqdn)
   client=LearnRestClient.start_client(fqdn)
   %{ "fqdn"=>fqdn, "fqdnAtom" => fqdnAtom, "client" => client }
   #demo = start_demo()
   # iex(16)> demo["client"]["dskMap"]["_2_1"]["externalId"]
   #"SYSTEM"
 end

   @doc """
   Create a new agent with the given 'fqdn'. We can have many of these.
   fqdn is a String containing a fully qualified domain name of the
   Learn host we are going to connect to.

   Parse the JSON in the response body to a tokenMap and return that.

   """
   def start_client(fqdn) do
     # Turn the fqdn String into an atom. This atom will be the name
     # for this Agent that is connecting to the remote server. This
     # Agent will hold key/value pairs for all the information regarding
     # this connection, including the current auth toke we get back when
     # we start, and the request/response for any time we make a call.
     # We'll use this setup as an opportunity to get the auth token
     # from the auth url learn/api/public/v1/oauth2/token. We'll also,
     # because this was written for a DSK tool, grab the DSKs for
     # the system and keep associated with the Agent for the system.
     # 2014.04.18 Storing the DSKs seemed like a good idea on first
     # writing. We'll revisit this later as it may not be necessary,
     # or good design.

     # 2017.12.29 MBK Moved the authorization off to a separate method. This so we can
     # switch from basic_auth to three-legged
     fqdnAtom = String.to_atom(fqdn)
     LearnRestClient.start_link(fqdnAtom)
     LearnRestClient.put(fqdnAtom, "FQDN", fqdn)
     {:ok, tokenMap} = get_authorization(fqdn)

     # Now we can do:
     # fqdn = "bd-partner-a-original.blackboard.com"
     # fqdnAtom = String.to_atom(fqdn)
     # client=LearnRestClient.start_client(fqdn)
     # LearnRestClient.get(fqdnAtom, "tokenMap")
     # client["dskMap"] client["tokenMap"]["access_token"] client["dskMap"]["_17_1"]["description"]
     # LearnRestClient.get(fqdnAtom, "dskMap")
     {:ok, intentionallyUnused, theDskMap} = LearnRestClient.get_data_sources(fqdn)
     {:ok, %{"fqdn"=>fqdn, "tokenMap" => tokenMap, "dskMap" => theDskMap}}
   end

   @doc """
      Call get_basic_access_token whenever you want an access token.
      We call this whether we have chosen basic-auth or three-legged-auth
   """
   def get_basic_access_token_map(fqdn) do
     fqdnAtom = String.to_atom(fqdn)
     if LearnRestClient.get(fqdnAtom, "tokenExpireTime") - System.system_time(:second) < 10 do
       fqdn = Atom.to_string(fqdnAtom)
       post_basic_auth(fqdn)
     end
     LearnRestClient.get(fqdnAtom,"tokenMap")
   end

   @doc """
    get_authorization is all any method that needs an access token needs to call
    In here we worry about whether we already have an access token, whether
    it's expired, whether we're doing 3-legged or basic, etc.
   """
   def get_authorization(fqdn) do
     # success returns a tuple {:ok, tokenMap}
     # Does the client currently have a token map? If not, get one.
     case tokenMap = LearnRestClient.get(String.to_atom(fqdn), "tokenMap") do
       nil -> tokenMap = post_basic_auth(fqdn)
       _ -> get_basic_access_token_map(fqdn)
     end
     {:ok, tokenMap}
  end

   ###### BASIC AUTH #####
   @doc """
   Basic Authroization. Return :ok with the tokenMap, or :error with an empty map
   """
   def post_basic_auth(fqdn) do
     fqdnAtom = String.to_atom(fqdn)
     url = get_oauth_url(fqdn)
     potionOptions = get_oauth_potion_options()
     response = HTTPotion.post(url, potionOptions)
     result = case response do
       %HTTPotion.Response{} ->
         {:ok, tokenMap} = Poison.decode(response.body) # Convert the Json in the response body to a map.
         now = System.system_time(:second)
         seconds_to_expire = tokenMap["expires_in"]
         expire_time = now + seconds_to_expire
         LearnRestClient.put(fqdnAtom, "tokenExpireTime", expire_time)
         temp = LearnRestClient.put(fqdnAtom, "tokenMap", tokenMap )
         {temp, tokenMap}

       %HTTPotion.ErrorResponse{} -> {:error, {}}

       _ -> {:error,{}}
     end

   end

   ##### COURSES #####

   @doc """
   Get Courses from the remote system specified by the fqdn
   Parses the JSON content in the response body to a map.
   Returns the Map.
   To Do: Implement Paging
   """
   def get_courses(fqdn) do
     fqdnAtom = String.to_atom(fqdn)
     url = get_courses_url(fqdn)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, coursesResponseMap} = Poison.decode(response.body)
     # Unlike DSKs, we don't store these in the LearnRestClient
     # We keep the DSKs around - because of an early design
     # decision that could possibly be changed later.
     {:ok, coursesResponseMap}
   end

   @doc """
   Get a Course from the remote system specified by the fqdn and courseId
   id is the PK1 in the format _123_1 as seen in the address field of the
   browser when accessing the course.
   Parses the JSON content in the response body to a map.
   Returns the Map.

   """
   def get_course(fqdn, id) do
     fqdnAtom = String.to_atom(fqdn)
     url = get_course_url(fqdn, id)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, course} = Poison.decode(response.body)
     {:ok, course}
   end

   @doc """
   Get a Course from the remote system specified by the fqdn and courseId
   courseId must be the courseId. This is a convenience method
   Parses the JSON content in the response body to a map.
   Returns the Map.

   """
   def get_course_with_courseId(fqdn, courseId) do
     get_course(fqdn,"courseId:"<>courseId)
   end

   @doc """
   Update the course with id (pk1 ex: _123_1) to have the new courseData
   """
   def update_course(fqdn, id, courseData) do
     fqdnAtom = String.to_atom(fqdn)
     {:ok, body} = Poison.encode(courseData)
     options = LearnRestClient.get_json_potion_options(fqdnAtom, body)
     courseUrl = LearnRestClient.get_course_url(fqdn, id)
     response = HTTPotion.patch(courseUrl, options)
     Logger.info response.body
     {:ok}
   end

   def update_course_with_courseId(fqdn, courseId, courseData) do
     update_course(fqdn, "courseId:"<>courseId, courseData)
   end

   @doc """
   Get the course URL.
   """
   def get_course_url(fqdn,id) do
     # Use String interpolation to take the value of the id and add it.
     "https://"<>fqdn<>@kv[:coursesendpoint]<>"/#{id}"
   end

   @doc """
   Get the courses URL.

   """
   def get_courses_url(fqdn) do
     "https://"<>fqdn<>@kv[:coursesendpoint]
   end

   ##### DATA SOURCES #####

   @doc """
   Get dataSources from the remote system specified by the fqdn
   Parses the JSON content in the response body to a map.
   Returns the Map. Looks like:
   %{"results" => [%{"description" => "Internal data source used for associating records that are created for use by the Bb system.",
     "externalId" => "INTERNAL", "id" => "_1_1"},... "id" => "_51_1"}]}
   To Do: Implement Paging
   """
   def get_data_sources(fqdn) do
     fqdnAtom = String.to_atom(fqdn)
     url = get_data_sources_url(fqdn)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, dsksResponseMap} = Poison.decode(response.body)
     LearnRestClient.put(fqdnAtom, "dsksResponseMap", dsksResponseMap)
     dskMap = LearnRestUtil.dsks_to_map(dsksResponseMap["results"],%{})
     LearnRestClient.put(fqdnAtom, "dskMap", dskMap)
     {:ok, dsksResponseMap, dskMap}
   end


   def get_nextpage_of_dsks(fqdn, nextpage) do
     # Logger.info "Enter LearnRestClient.get_nextpage_of_memberships"
     fqdnAtom = String.to_atom(fqdn)
     url = "https://"<>fqdn<>"#{nextpage}"
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, dsks} = Poison.decode(response.body)
     # Logger.info "Exit LearnRestClient.get_nextpage_of_memberships"
     {:ok, dsks}
   end

   @doc """
   Get the dataSources URL.

   """
   def get_data_sources_url(fqdn) do
     "https://"<>fqdn<>"/learn/api/public/v1/dataSources"
   end

   @doc """
   Get the json HTTPotion options, where options are a list [] to
   pass to HTTPotion, NOT HTTP options.

   """
   def get_json_potion_options(fqdnAtom, body) do
     headers = LearnRestClient.get_json_request_headers(fqdnAtom)
     [body: "#{get_json_request_body(body)}",
      headers: headers
     ]
   end

   @doc """
   Get the json request body.

   """
   def get_json_request_body(body) do
     "#{body}"
   end

   @doc """
   Get the json request headers, where the headers are key/value comma seperated
   list. Also, check the accessToken expiry. Refresh as necessary.
   The other option is to look for the following on responses..
   {:ok, %{"message" => "Bearer token is invalid", "status" => 401}}

   """
   def get_json_request_headers(fqdnAtom) do
     # get_authorization dynamically gets either the cached token or
     # gets a new one, using  basic auth or three-legged.
     {:ok, tokenMap} = get_authorization(Atom.to_string(fqdnAtom))
     accessToken = tokenMap["access_token"]
     # Return the list of header items.
     ["Content-Type": "application/json", "Authorization": "Bearer #{accessToken}"]
   end


   ##### MEMBERSHIPS #####

   @doc """
   Get the course memberships URL.

   """
   def get_memberships_url_for_course(fqdn, courseId) do
     # Use String interpolation again.
     "https://"<>fqdn<>@kv[:coursesendpoint]<>"/#{courseId}/users"
   end

   @doc """
   Get the course memberships URL, with an offset.

   """
   def get_memberships_url_for_course(fqdn, courseId, offset) do
     # Use String interpolation again.
     "https://"<>fqdn<>@kv[:coursesendpoint]<>"/#{courseId}/users?offset=#{offset}"
   end

   def get_membership_url(fqdn, courseId, userId) do
     "https://"<>fqdn<>@kv[:coursesendpoint]<>"/#{courseId}/users/#{userId}"
   end

   @doc """
   Get Memberships from the remote system specified by the fqdn and courseId
   id is the PK1 in the format _123_1 as seen in the address field of the
   browser when accessing the course.
   Parses the JSON content in the response body to a map.
   Returns the Map.

   """
   def get_memberships_for_course(fqdn, id) do
     # Logger.info "Enter LearnRestClient.get_memberships_for_course id:#{id}"
     fqdnAtom = String.to_atom(fqdn)
     url = get_memberships_url_for_course(fqdn, id)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, memberships} = Poison.decode(response.body)
     # Logger.info "Exit LearnRestClient.get_memberships_for_course"
     {:ok, memberships}
   end

   @doc """
   Get Memberships from the remote system specified by the fqdn, courseId and offset
   id is the PK1 in the format _123_1 as seen in the address field of the
   browser when accessing the course.
   Parses the JSON content in the response body to a map.
   Returns the Map.

   """
   def get_memberships_for_course(fqdn, id, offset) do
     # Logger.info "Enter LearnRestClient.get_memberships_for_course id:#{id}"
     fqdnAtom = String.to_atom(fqdn)
     url = get_memberships_url_for_course(fqdn, id, offset)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, memberships} = Poison.decode(response.body)
     # Logger.info "Exit LearnRestClient.get_memberships_for_course"
     {:ok, memberships}
   end

   def get_membership(fqdn, course_id, user_name) do
     fqdnAtom = String.to_atom(fqdn)
     url = get_membership_url(fqdn, "courseId:"<>course_id, "userName:"<>user_name)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, membership} = Poison.decode(response.body)
     {:ok, membership}
   end

   @doc """
   Update the user with userId to have the new userData
   """
   def update_membership(fqdn, course_id, user_name, membershipData) do
     fqdnAtom = String.to_atom(fqdn)
     {:ok, body} = Poison.encode(membershipData)
     options = LearnRestClient.get_json_potion_options(fqdnAtom, body)
     membershipUrl = LearnRestClient.get_membership_url(fqdn, "courseId:"<>course_id, "userName:"<>user_name)
     response = HTTPotion.patch(membershipUrl, options)
     Logger.info response.body
     {:ok}
   end

   @doc """
   Get Memberships from the remote system specified by the fqdn and courseId
   courseId must be the courseId. This is a convenience method
   Parses the JSON content in the response body to a map.
   Returns the Map.

   """
   def get_memberships_for_courseId(fqdn, courseId) do
     get_memberships_for_course(fqdn,"courseId:"<>courseId)
   end


   @doc """
   Get Memberships from the remote system specified by the fqdn, courseId
   and offset.
   courseId must be the courseId. This is a convenience method
   Parses the JSON content in the response body to a map.
   Returns the Map.

   """
   def get_memberships_for_courseId(fqdn, courseId, offset) do
     get_memberships_for_course(fqdn,"courseId:"<>courseId, offset)
   end

   def get_nextpage_of_memberships(fqdn, nextpage) do
     # Logger.info "Enter LearnRestClient.get_nextpage_of_memberships"
     fqdnAtom = String.to_atom(fqdn)
     url = "https://"<>fqdn<>"#{nextpage}"
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, memberships} = Poison.decode(response.body)
     # Logger.info "Exit LearnRestClient.get_nextpage_of_memberships"
     {:ok, memberships}
   end

  #### OAuth ####

  @doc """
  Get the Oauth URL.

  """
  def get_oauth_url(fqdn) do
    "https://"<>fqdn<>@kv[:tokenendpoint]
  end

  @doc """
  Get the oauth request body.

  """
  def get_oauth_request_body() do
    "grant_type=client_credentials"
  end

  @doc """
  Get the oauth HTTPotion options, where options are a list [] to
  pass to HTTPotion, NOT HTTP options.

  """
  def get_oauth_potion_options() do
    appkey = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:appkey]
    appsecret = Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:appsecret]
    [body: "#{get_oauth_request_body()}",
     headers: ["Content-Type": "application/x-www-form-urlencoded"],
     basic_auth: {appkey,appsecret}]
  end

  ##### USERS #####

  @doc """
  Get Users from the remote system specified by the fqdn
  Parses the JSON content in the response body to a map.
  Returns the Map.
  To Do: Implement Paging
  """
  def get_users(fqdn) do
    fqdnAtom = String.to_atom(fqdn)
    url = get_users_url(fqdn)
    potionOptions = get_json_potion_options(fqdnAtom,"")
    response = HTTPotion.get(url, potionOptions)
    {:ok, usersResponseMap} = Poison.decode(response.body)
    # Unlike DSKs, we don't store these in the LearnRestClient
    # We keep the DSKs around - because of an early design
    # decision that could possibly be changed later.
    {:ok, usersResponseMap}
  end

  @doc """
  Get a User from the remote system specified by the fqdn and userId
  userId is either the primary Learn id in the form _x_y. Example _1_7.
  or userName:sjackson, externalId:jsmith, or the
  uuid:915c7567d76d444abf1eed56aad3beb5
  Parses the JSON content in the response body to a map.
  Returns the Map.

  """
  def get_user(fqdn, userId) do
    fqdnAtom = String.to_atom(fqdn)
    url = get_user_url(fqdn, userId)
    potionOptions = get_json_potion_options(fqdnAtom,"")
    response = HTTPotion.get(url, potionOptions)
    {:ok, user} = Poison.decode(response.body)
    {:ok, user}
  end

  @doc """
  Get a User from the remote system specified by the fqdn and userId
  userId must be the userName. This is a convenience method
  Parses the JSON content in the response body to a map.
  Returns the Map.

  """
  def get_user_with_userName(fqdn, userName) do
    get_user(fqdn,"userName:"<>userName)
  end

  @doc """
  Update the user with userId to have the new userData
  """
  def update_user(fqdn, userId, userData) do
    fqdnAtom = String.to_atom(fqdn)
    {:ok, body} = Poison.encode(userData)
    options = LearnRestClient.get_json_potion_options(fqdnAtom, body)
    userUrl = LearnRestClient.get_user_url(fqdn, userId)
    response = HTTPotion.patch(userUrl, options)
    Logger.info response.body
    {:ok}
  end

  def update_user_with_userName(fqdn, userName, userData) do
    update_user(fqdn, "userName:"<>userName, userData)
  end

  @doc """
  Get the user URL.
  """
  def get_user_url(fqdn,userId) do
    # Use String interpolation to take the value of the userId and add it.
    "https://"<>fqdn<>@kv[:usersendpoint]<>"/#{userId}"
  end

  @doc """
  Get the users URL.

  """
  def get_users_url(fqdn) do
    "https://"<>fqdn<>@kv[:usersendpoint]
  end

end #defmodule LearnRestClient
