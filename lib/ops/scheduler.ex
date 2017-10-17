defmodule OPS.Scheduler do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :ops

  alias Crontab.CronExpression.Parser
  alias Quantum.Job
  alias OPS.MedicationDispenses
  import OPS.Declarations, only: [approve_declarations: 0, terminate_declarations: 0]

  def create_jobs do
    __MODULE__.new_job()
    |> Job.set_name(:declaration_auto_approve)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:declaration_auto_approve]))
    |> Job.set_task(&approve_declarations/0)
    |> __MODULE__.add_job()

    __MODULE__.new_job()
    |> Job.set_name(:medication_dispense_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:medication_dispense_autotermination]))
    |> Job.set_task(fn ->
      MedicationDispenses.terminate(get_config()[:medication_dispense_expiration])
    end)
    |> __MODULE__.add_job()

    __MODULE__.new_job()
    |> Job.set_name(:declaration_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:declaration_autotermination]))
    |> Job.set_task(&terminate_declarations/0)
    |> __MODULE__.add_job()
  end

  defp get_config do
    Confex.fetch_env!(:ops, __MODULE__)
  end
end
