use Mix.Config

config :core, Core.ReadRepo,
  database: {:system, :string, "READ_DB_NAME"},
  username: {:system, :string, "READ_DB_USER"},
  password: {:system, :string, "READ_DB_PASSWORD"},
  hostname: {:system, :string, "READ_DB_HOST"},
  port: {:system, :integer, "READ_DB_PORT"},
  pool_size: {:system, :integer, "READ_DB_POOL_SIZE", 10},
  timeout: 15_000

config :core, Core.Repo,
  database: {:system, :string, "DB_NAME"},
  username: {:system, :string, "DB_USER"},
  password: {:system, :string, "DB_PASSWORD"},
  hostname: {:system, :string, "DB_HOST"},
  port: {:system, :integer, "DB_PORT"},
  pool_size: {:system, :integer, "DB_POOL_SIZE", 10},
  timeout: 15_000

config :core, Core.BlockRepo,
  database: {:system, :string, "BLOCK_DB_NAME"},
  username: {:system, :string, "BLOCK_DB_USER"},
  password: {:system, :string, "BLOCK_DB_PASSWORD"},
  hostname: {:system, :string, "BLOCK_DB_HOST"},
  port: {:system, :integer, "BLOCK_DB_PORT"},
  pool_size: {:system, :integer, "BLOCK_DB_POOL_SIZE", 10},
  timeout: 15_000

config :core, Core.EventManagerRepo,
  database: {:system, :string, "EVENT_MANAGER_DB_NAME"},
  username: {:system, :string, "EVENT_MANAGER_DB_USER"},
  password: {:system, :string, "EVENT_MANAGER_DB_PASSWORD"},
  hostname: {:system, :string, "EVENT_MANAGER_DB_HOST"},
  port: {:system, :integer, "EVENT_MANAGER_DB_PORT"},
  pool_size: {:system, :integer, "EVENT_MANAGER_DB_POOL_SIZE", 10},
  timeout: 15_000
