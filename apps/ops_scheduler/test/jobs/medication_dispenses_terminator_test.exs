defmodule OpsScheduler.Jobs.MedicationDispensesTerminatorTest do
  @moduledoc false

  use Core.DataCase
  import Mox
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.Repo
  alias OpsScheduler.Jobs.MedicationDispensesTerminator

  setup :verify_on_exit!

  test "run/0" do
    expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :second)
    insert(:medication_dispense, inserted_at: inserted_at)
    assert 1 == count_by_status(MedicationDispense.status(:new))

    MedicationDispensesTerminator.run()
    assert 0 == count_by_status(MedicationDispense.status(:new))
    assert 1 == count_by_status(MedicationDispense.status(:expired))
  end

  defp count_by_status(status) do
    MedicationDispense
    |> where([md], md.status == ^status)
    |> select([md], count(md.id))
    |> Repo.one()
  end
end
