use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true

config :ops, api_resolvers: [il: IlMock]

# Configure your databases
config :ops, OPS.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ops_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :ops, OPS.BlockRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "seed_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :ops, OPS.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "event_manager_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :ops, OPS.DeclarationsAutoProcessor, termination_batch_size: 1

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ops, OPS.Web.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Run acceptance test in concurrent mode
config :ops, sql_sandbox: true

# Configures IL API
config :ops, OPS.API.IL, endpoint: {:system, "IL_ENDPOINT", "http://localhost:4040"}

# Configures declaration terminator
config :ops, OPS.DeclarationTerminator,
  frequency: 100,
  utc_interval: {0, 23}

# Configures declaration auto approve
config :ops, OPS.DeclarationAutoApprove,
  frequency: 300,
  utc_interval: {0, 23}

config :ops,
  mock: [
    port: {:system, :integer, "TEST_MOCK_PORT", 4040},
    host: {:system, "TEST_MOCK_HOST", "localhost"}
  ]
