use Mix.Config

# Configuration for test environment

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :ops, OPS.Web.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT", 4000}],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :ops, OPS.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ops_dev",
  hostname: "localhost",
  pool_size: 10

config :ops, OPS.BlockRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "seed_dev",
  hostname: "localhost",
  pool_size: 10

config :ops, OPS.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "event_manager_dev",
  hostname: "localhost",
  pool_size: 10

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
