# PhoenixDSK
# See PHOENIX_LICENSE.md for the Phoenix Framework License
# See BLACKBOARD_LICENSE.md for the license pertaining to the portions of this application specific to Blackboard Learn.

To try the different modules in iex:
  * $ iex -S mix

To start this Phoenix app:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `npm install`
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## This specific application's organization
LearnRestClient and LearnRestUtil encapsulate code necessary to make REST calls
to a Learn server. LearnRestClient uses an Elixir Agent to hold the state of a
REST client for multiple Learn servers.

When you start the client you're associating a FQDN with the client.
Example: LearnRestClient.start_client("myhost.xyz.com")
The above starts an Agent named String.to_atom("myhost.xyz.com") and tells it
that the state it will encapsulate is a Map. Then start_client calls the
Learn OAuth endpoint to get the token used for successive calls. The result
is JSON which we store in a Map, tokenMap. This tokenMap is stored in the
LearnRestClient Map, and the key is "tokenMap". The last thing that
LearnRestClient.start_client does is to call the Learn endpoint to get
the Learn system's DSKs. Here the result is a list of DSKs where each DSK
is a Map. We turn the list into a map of maps, so that we can quickly access
a given DSK.

The rest of this application is a Phoenix MVC web application. We store the
public configuration in config/config.exs. This only consists of learnserver:
and learnserverAtom, the Learn server that we work with for the demo. Our
private configuration is in confi/dev.exs, consisting of the login information
to our local database, and our REST application key and secret.

Before we run this application we must define a REST application on
developer.blackboard.com. Then we use the provided key and secret in
the dev.exs file, as this is the application. We configure the Learn server
REST integration for this application using the provided Application ID.

The last piece that is unique to this application is that we define a worker in
phoenixDSK/restclientagent.ex. This worker will start the LearnRestClient
for us when we load the application, connecting to the :learnserver we
defined in config.exs. We tell this application to start the worker in the
start section of lib/phoenixDSK.ex with the line:
 worker(PhoenixDSK.RestClientAgent,[])

 Defining config in config.exs lets us do things like:
 Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:appkey]
 Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
 Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserverAtom]
 anywhere in the application.

 Because the LearnRestClient was started by a worker, we can use it anywhere.
 Example:
 fqdn=Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
 users = LearnRestClient.get_users(fqdn)

 2017.04.10 - MBK - We don't do any paging as of this writing so we only get the first page.
 This covers what I've written so far.
