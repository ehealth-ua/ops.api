defmodule OpsScheduler.Jobs.MedicationDispensesTerminatorTest do
  @moduledoc false

  use Core.DataCase
  import Mox
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.Repo
  alias OpsScheduler.Jobs.MedicationDispensesTerminator

  setup :verify_on_exit!

  test "run/0" do
    termination_batch_size = Application.get_env(:ops_scheduler, MedicationDispensesTerminator)[:termination_batch_size]
    terminate_count = termination_batch_size * 2 + 1
    expect(KafkaMock, :publish_to_event_manager, terminate_count, fn _ -> :ok end)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :second)

    Enum.each(1..terminate_count, fn _ -> insert(:medication_dispense, inserted_at: inserted_at) end)
    assert terminate_count == count_by_status(MedicationDispense.status(:new))

    MedicationDispensesTerminator.run()
    assert 0 == count_by_status(MedicationDispense.status(:new))
    assert terminate_count == count_by_status(MedicationDispense.status(:expired))
  end

  defp count_by_status(status) do
    MedicationDispense
    |> where([md], md.status == ^status)
    |> select([md], count(md.id))
    |> Repo.one()
  end
end
