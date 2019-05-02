use Mix.Config

config :ops_scheduler, OpsScheduler.Jobs.MedicationDispensesTerminator, termination_batch_size: 5
config :ops_scheduler, OpsScheduler.Jobs.MedicationRequestsTerminator, termination_batch_size: 5

# Print only warnings and errors during test
config :logger, level: :warn
