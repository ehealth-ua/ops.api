use Mix.Config

config :core, Core.ReadRepo,
  username: "postgres",
  password: "postgres",
  database: "ops_dev",
  hostname: "localhost",
  pool_size: 10

config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  database: "ops_dev",
  hostname: "localhost",
  pool_size: 10

config :core, Core.BlockRepo,
  username: "postgres",
  password: "postgres",
  database: "seed_dev",
  hostname: "localhost",
  pool_size: 10

config :core, Core.EventManagerRepo,
  username: "postgres",
  password: "postgres",
  database: "event_manager_dev",
  hostname: "localhost",
  pool_size: 10
