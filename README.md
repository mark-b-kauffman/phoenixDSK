Notice: ARCHIVED REPO. I'M NO LONGER SUPPORTING THIS CODE. IT IS OLD AND NEEDS ALL LIBS IT USES UPDATED TO THE LATEST, SECURE VERSIONS. IF YOU NEED IT YOU WILL NEED TO UPDATE IT AS IT IS NO LONGER WORKING WITH HEROKU. THERE IS NO PUSH BUTTON SOLUTION FOR NON-DEVELOPERS. I'M LEAVING IT AVAILABLE HERE FOR THE TIME BEING FOR REFERENCE.

# PhoenixDSK
See BLACKBOARD_LICENSE.md for the license pertaining to the portions of this application specific to Blackboard Learn. 

See PHOENIX_LICENSE.md for the Phoenix Framework License

## Basic Authentication
Reference https://medium.com/@paulfedory/basic-authentication-in-your-phoenix-app-fa24e57baa8
Development user and password are user2/secret2. See router.ex for setup. Will be using environment variables for production user and password. This app must be served over HTTPS. Then, given that we're using the following in the router, plug :protect_from_forgery, plug :put_secure_browser_headers, your browser is protected from someone spoofing this app, and you've guaranteed that only you can log in to this app that for which only you know the user and password. You're responsible for making your password long and complex enough that it's secure from dictionary attacks.

## Quick and Easy Deployment to Heroku:
1. Get an application ID, key, and Secret from https://developer.blackboard.com
2. Set up the REST application on your Learn server using the application ID from #1.
3. Click the Deploy button and fill in the application key, secret, and Learn URL.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/mark-b-kauffman/phoenixDSK)

4. Wait a bit while the application deploys to your Heroku server.
5. Click the View button.
6. Remove the trailing /register in the address of the page that is displayed, then hit enter to view the application.

Note: The Heroku configuration is contained in the top-level file app.json.

## Notes for building and deploying locally:

2017.05.27 MBK I built this as a default Phoenix project using an Ecto Repo on to of Postgres.
Since I'm not using any of that functionality for this project I decided to remove it. I did so
using the procedure described with the following:
https://stackoverflow.com/questions/38497148/remove-ecto-from-existing-phoenix-project
https://github.com/ospaarmann/remove_ecto_from_phoenix/commit/95f9f1c8c26c7a63f5563eb29491235bc64c41fb

git reset --hard origin/master Then copy the hidden dev.exs file for use.
If you don't have a hidden dev.exs file, then modify the one you've pulled from github to have your key and secret.
Then, because of the mods made to run this on Heroku, you will need to set 3 environment variables to run locally.
The following works on the Mac OSX with a Bash shell.
$ export LEARNSERVER=<The FQDN of your Learn server here.>
$ export APP_KEY=<Your REST APP Key here.>
$ export APP_SECRET=<Your REST APP Secret here.>

2015.05.30 MBK TODO
HTTPoison, Verify Cert for SSL, eliminate possibility of MITM
Refresh REST Auth token on expiration
Paging on the dsks and users index pages.

To try the different modules in iex:
  * Modify dev.exs to use your Rest Applications Key and Secret
  * $ iex -S mix

To start this Phoenix app you must do the following the first time after checkout:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install`
  * Modify dev.exs to use your REST Application Key and Secret

The above only need doing the first time, after that you can just start the server with the following:
  * Start Phoenix endpoint with `mix phoenix.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Troubleshooting
If things stop working between builds, try wiping everything that gets built and start back with the instructions above for first time after checkout:
  *  rm mix.lock
  *  rm -rf deps
  *  rm -rf _build
  *  rm -rf priv
  *  rm -rf node_modules
  *  sudo rm -rf ~/.npm
  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `npm install`

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

## This specific application's organization follows:

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

Before we run this web app we must define a REST application on
developer.blackboard.com. Then we use the provided key and secret in
the dev.exs file, as this is the application. We configure the Learn server
REST integration for this application using the provided Application ID.

The last piece that is unique to this web app is that we define a worker in
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
 Examples:
 fqdn=Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:learnserver]
 {:ok, users} = LearnRestClient.get_users(fqdn)

 LearnRestClient.all(fqdn,Learn.User)
