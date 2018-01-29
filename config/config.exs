# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :ops, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:ops, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
# Or read environment variables in runtime (!) as:
#
#     :var_name, "${ENV_VAR_NAME}"
config :ops,
  ecto_repos: [OPS.Repo, OPS.BlockRepo, OPS.EventManagerRepo],
  env: Mix.env()

# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration

config :ops,
  namespace: OPS,
  system_user: {:system, "EHEALTH_SYSTEM_USER", "4261eacf-8008-4e62-899f-de1e2f7065f0"}

config :ops, OPS.Scheduler,
  declaration_auto_approve: {:system, :string, "DECLARATION_AUTO_APPROVE_SCHEDULE", "0 0-4 * * *"},
  medication_dispense_autotermination: {:system, :string, "MEDICATION_DISPENSE_AUTOTERMINATION_SCHEDULE", "* * * * *"},
  medication_dispense_expiration: {:system, :integer, "MEDICATION_DISPENSE_EXPIRATION", 10},
  declaration_autotermination: {:system, :string, "DECLARATION_AUTOTERMINATION_SCHEDULE", "0 0-4 * * *"},
  medication_request_autotermination: {:system, :string, "MEDICATION_REQUEST_AUTOTERMINATION_SCHEDULE", "* * * * *"},
  close_block: {:system, :string, "CLOSE_BLOCK_SCHEDULE", "0 * * * *"}

# Configures the endpoint
config :ops, OPS.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4LcL78vtzM1yVeVCuY1351HuU/62qpTtDKykdJxAKKgwnTtH5JzkXNEUouzDBc1D",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

# Configures IL endpoint
config :ops, OPS.API.IL,
  # TODO: update Chart configs
  endpoint: {:system, "IL_ENDPOINT", "http://api-svc.il"},
  timeouts: [
    connect_timeout: {:system, :integer, "IL_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "IL_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "IL_REQUEST_TIMEOUT", 30_000}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

config :ops, :block_versions, %{
  "v1" => "
    WITH concat AS (
      SELECT
        ARRAY_TO_STRING(ARRAY_AGG(
          CONCAT(
            id,
            employee_id,
            start_date,
            end_date,
            signed_at,
            created_by,
            scope,
            division_id,
            legal_entity_id,
            inserted_at,
            declaration_request_id,
            person_id,
            seed
          ) ORDER BY id ASC
        ), '') AS value FROM declarations
        WHERE inserted_at > $1 AND inserted_at <= $2
    )
    SELECT digest(concat(value), 'sha512')::text AS value FROM concat
  ",
  "v2" => "
    WITH concat AS (
      SELECT
        ARRAY_TO_STRING(ARRAY_AGG(
          CONCAT(
            id,
            employee_id,
            start_date,
            end_date,
            signed_at,
            created_by,
            scope,
            division_id,
            legal_entity_id,
            inserted_at,
            declaration_request_id,
            person_id,
            seed,
            '$2'
          ) ORDER BY id ASC
        ), '') AS value FROM declarations
        WHERE inserted_at > $1 AND inserted_at <= $2
    )
    SELECT digest(concat(value), 'sha512')::text AS value FROM concat
  "
}

# Must be adjusted every time current_block_version is appended with new version
config :ops, :current_block_version, "v2"

config :ecto_trail, table_name: "audit_log"

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env()}.exs"
