use Mix.Config

config :core, Core.ReadRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ops_dev",
  hostname: "localhost",
  pool_size: 10

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ops_dev",
  hostname: "localhost",
  pool_size: 10

config :core, Core.BlockRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "seed_dev",
  hostname: "localhost",
  pool_size: 10

config :core, Core.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "event_manager_dev",
  hostname: "localhost",
  pool_size: 10
