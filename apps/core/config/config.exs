# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :core,
  ecto_repos: [Core.Repo, Core.BlockRepo, Core.EventManagerRepo]

config :ecto, json_library: Jason

config :core,
  system_user: {:system, "EHEALTH_SYSTEM_USER", "4261eacf-8008-4e62-899f-de1e2f7065f0"},
  api_resolvers: [
    il: Core.API.IL
  ],
  repos: [
    read_repo: Core.ReadRepo
  ]

config :core, Core.AuditLogs, max_audit_record_insert: 100

config :core, :block_versions, %{
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

config :core, Core.API.IL,
  endpoint: {:system, "IL_ENDPOINT", "http://api-svc.il"},
  timeouts: [
    connect_timeout: {:system, :integer, "IL_REQUEST_TIMEOUT", 30_000},
    recv_timeout: {:system, :integer, "IL_REQUEST_TIMEOUT", 30_000},
    timeout: {:system, :integer, "IL_REQUEST_TIMEOUT", 30_000}
  ]

# Must be adjusted every time current_block_version is appended with new version
config :core, :current_block_version, "v2"

config :ecto_trail, table_name: "audit_log"

import_config "#{Mix.env()}.exs"
