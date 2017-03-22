defmodule LearnRestClient do

  # We want to be able to access these module constants outside of the module.
  # We define a key-value map with all of them. The appkey and secret are not valid.
  # Change them to be the app key and secret you get for your app from developer.blackboard.com.
  @kv %{appkey: "d128e50d-c91e-47d3-a97e-9d0c8a77fb5e",
        appsecret: "jZljsyAyUnthIoRl370PYC36bGXixS53",
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
  # We're going to use the KV Bucket to maint state regarding our
  # hostname, the auth token for a particular host, and anything
  # that I can't think of at the moment that we'll need to
  # have 'knowledge' of the particular Learn server the code is 'talking'
  # to by making REST calls. The second section will implement the different
  # REST calls as functions to save the different modules making the REST calls
  # having to re-implement the code.

  @doc """
  Start the agent with the given 'name'. We can have many of these.
  name must be an atom.

  """
  def start_link(name) do
    Agent.start_link(fn -> %{} end, name: name)
  end

  @doc """
  Get the value speced by a key from the 'bucket' with the given name.
  name is an atom, key is a string
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
     fqdnAtom = String.to_atom(fqdn)
     Agent.start_link(fn -> %{} end, name: fqdnAtom)
     LearnRestClient.put(fqdnAtom, "FQDN", fqdn)
     url = get_oauth_url(fqdn)
     potionOptions = get_oauth_potion_options()
     response = HTTPotion.post(url, potionOptions)
     {:ok, tokenMap} = Poison.decode(response.body) # Convert the Json in the response body to a map.
     LearnRestClient.put(fqdnAtom, "tokenMap", tokenMap )
     # Now we can do:
     # fqdn = "bd-partner-a-original.blackboard.com"
     # fqdnAtom = String.to_atom(fqdn)
     # client=LearnRestClient.start_client(fqdn)
     # LearnRestClient.get(fqdnAtom, "tokenMap")
     # client["dskMap"] client["tokenMap"]["access_token"] client["dskMap"]["_17_1"]["description"]
     # LearnRestClient.get(fqdnAtom, "dskMap")
     dsks = LearnRestClient.get_data_sources(fqdn)
     dskMap = LearnRestUtil.dsks_to_map(dsks["results"], %{})
     LearnRestClient.put(fqdnAtom, "dskMap", dskMap)
     %{"tokenMap" => tokenMap, "dskMap" => dskMap}
   end

   @doc """
   Get dataSources from the remote system specified by the fqdn
   Parses the JSON content in the response body to a map.
   Returns the Map. Looks like:
   %{"results" => [%{"description" => "Internal data source used for associating records that are created for use by the Bb system.",
     "externalId" => "INTERNAL", "id" => "_1_1"},... "id" => "_51_1"}]}

   """
   def get_data_sources(fqdn) do
     fqdnAtom = String.to_atom(fqdn)
     url = get_data_sources_url(fqdn)
     potionOptions = get_json_potion_options(fqdnAtom,"")
     response = HTTPotion.get(url, potionOptions)
     {:ok, dataSourcesMap} = Poison.decode(response.body)
     LearnRestClient.put(fqdnAtom, "dataSourcesMap", dataSourcesMap)
     dataSourcesMap
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
     "{#{body}}"
   end

   @doc """
   Get the json request headers, where the headers are key/value comma seperated
   list.

   """
   def get_json_request_headers(fqdnAtom) do
     accessToken = LearnRestClient.get(fqdnAtom,"tokenMap")["access_token"]
      ["Content-Type": "application/json", "Authorization": "Bearer #{accessToken}"]
   end

   @doc """
   Get the course memberships URL.

   """
   def get_memberships_url(fqdn, courseId) do
     # Use String interpolation again.
     "https://"<>fqdn<>"/learn/api/public/v1/courses/#{courseId}/users"
   end

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
    [body: "#{get_oauth_request_body()}",
     headers: ["Content-Type": "application/x-www-form-urlencoded"],
     basic_auth: {"#{@kv[:appkey]}","#{@kv[:appsecret]}"}]
  end

  @doc """
  Get Users from the remote system specified by the fqdn
  Parses the JSON content in the response body to a map.
  Returns the Map.

  """
  def get_users(fqdn) do
    fqdnAtom = String.to_atom(fqdn)
    url = get_users_url(fqdn)
    potionOptions = get_json_potion_options(fqdnAtom,"")
    response = HTTPotion.get(url, potionOptions)
    {:ok, usersMap} = Poison.decode(response.body)
    usersMap
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
    user
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
