use Mix.Config

config :ex_unit, capture_log: true

config :core,
  api_resolvers: [il: IlMock],
  repos: [
    read_repo: Core.Repo
  ]

config :core, Core.ReadRepo,
  username: "postgres",
  password: "postgres",
  database: "ops_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "ops_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :core, Core.BlockRepo,
  username: "postgres",
  password: "postgres",
  database: "seed_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

# Print only warnings and errors during test
config :logger, level: :warn

# Run acceptance test in concurrent mode
config :core,
  sql_sandbox: true,
  kafka: [
    producer: KafkaMock
  ]
