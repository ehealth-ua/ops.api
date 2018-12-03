use Mix.Config

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}",
  pool_size: "${DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.BlockRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${BLOCK_DB_NAME}",
  username: "${BLOCK_DB_USER}",
  password: "${BLOCK_DB_PASSWORD}",
  hostname: "${BLOCK_DB_HOST}",
  port: "${BLOCK_DB_PORT}",
  pool_size: "${BLOCK_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${EVENT_MANAGER_DB_NAME}",
  username: "${EVENT_MANAGER_DB_USER}",
  password: "${EVENT_MANAGER_DB_PASSWORD}",
  hostname: "${EVENT_MANAGER_DB_HOST}",
  port: "${EVENT_MANAGER_DB_PORT}",
  pool_size: "${EVENT_MANAGER_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]
