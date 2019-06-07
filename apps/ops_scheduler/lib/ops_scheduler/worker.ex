defmodule OpsScheduler.Worker do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :ops_scheduler

  alias Crontab.CronExpression.Parser
  alias OpsScheduler.Jobs.CacheDeclarationsCountJob
  alias OpsScheduler.Jobs.CacheMedicationRequestsCountJob
  alias OpsScheduler.Jobs.CloseBlockJob
  alias OpsScheduler.Jobs.DeclarationsApprove
  alias OpsScheduler.Jobs.DeclarationsTerminator
  alias OpsScheduler.Jobs.MedicationDispensesTerminator
  alias OpsScheduler.Jobs.MedicationRequestsTerminator
  alias Quantum.Job
  alias Quantum.RunStrategy.Local

  def create_jobs do
    create_job(&CacheDeclarationsCountJob.run/0, :cache_declarations_count_job_schedule)
    create_job(&CacheMedicationRequestsCountJob.run/0, :cache_medication_requests_count_job_schedule)
    create_job(&DeclarationsApprove.run/0, :declarations_approve_schedule)
    create_job(&DeclarationsTerminator.run/0, :declarations_terminator_schedule)
    create_job(&MedicationDispensesTerminator.run/0, :medication_dispenses_terminator_schedule)
    create_job(&MedicationRequestsTerminator.run/0, :medication_requests_terminator_schedule)
    create_job(&CloseBlockJob.run/0, :close_block_job_schedule)
  end

  defp create_job(fun, config_name) do
    config = Confex.fetch_env!(:ops_scheduler, __MODULE__)

    __MODULE__.new_job()
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(config[config_name]))
    |> Job.set_task(fun)
    |> Job.set_run_strategy(%Local{})
    |> __MODULE__.add_job()
  end
end
