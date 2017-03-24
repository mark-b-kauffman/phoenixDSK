use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :phoenixDSK, PhoenixDSK.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :phoenixDSK, PhoenixDSK.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]
# This Learn REST Application's Key and secret
# These are held by the application developer and not to be
# shared outside that organization. Otherwise someone can
# spoof your application. Read these with:
# Application.get_env(:phoenixDSK, PhoenixDSK.Endpoint)[:appkey]
config :phoenixDSK, PhoenixDSK.Endpoint,
  appkey: "d128e50d-c91e-47d3-a97e-noneofyourbiz",
  appsecret: "jZljsn00thingforuhereC36bGXixS52"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :phoenixDSK, PhoenixDSK.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "xyzzy",
  database: "phoenixdsk_dev",
  hostname: "localhost",
  pool_size: 10
