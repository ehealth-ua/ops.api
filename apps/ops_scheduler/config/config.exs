use Mix.Config

config :ops_scheduler, OpsScheduler.Worker,
  cache_declarations_count_job_schedule: {:system, :string, "CACHE_DECLARATIONS_COUNT_JOB_SCHEDULE", "0 * * * *"},
  cache_medication_requests_count_job_schedule:
    {:system, :string, "CACHE_MEDICATION_REQUESTS_COUNT_JOB_SCHEDULE", "0 * * * *"},
  declarations_approve_schedule: {:system, :string, "DECLARATION_AUTO_APPROVE_SCHEDULE", "0 0-4 * * *"},
  declarations_terminator_schedule: {:system, :string, "DECLARATION_AUTOTERMINATION_SCHEDULE", "0 0-4 * * *"},
  medication_dispenses_terminator_schedule:
    {:system, :string, "MEDICATION_DISPENSE_AUTOTERMINATION_SCHEDULE", "* * * * *"},
  medication_requests_terminator_schedule:
    {:system, :string, "MEDICATION_REQUEST_AUTOTERMINATION_SCHEDULE", "* * * * *"},
  close_block_job_schedule: {:system, :string, "CLOSE_BLOCK_SCHEDULE", "0 * * * *"}

config :ops_scheduler, OpsScheduler.Jobs.DeclarationsTerminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 10}

config :ops_scheduler, OpsScheduler.Jobs.DeclarationsApprove,
  approve_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 10}

config :ops_scheduler, OpsScheduler.Jobs.MedicationRequestsTerminator,
  termination_batch_size: {:system, :integer, "MEDICATION_REQUEST_AUTOTERMINATION_BATCH", 10}

config :ops_scheduler, OpsScheduler.Jobs.MedicationDispensesTerminator,
  expiration: {:system, :integer, "MEDICATION_DISPENSE_EXPIRATION", 10},
  termination_batch_size: {:system, :integer, "MEDICATION_DISPENSE_AUTOTERMINATION_BATCH", 10}

import_config "#{Mix.env()}.exs"
