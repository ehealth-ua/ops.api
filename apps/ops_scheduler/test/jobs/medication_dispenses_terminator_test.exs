defmodule OpsScheduler.Jobs.MedicationDispensesTerminatorTest do
  @moduledoc false

  use Core.DataCase
  alias Core.EventManager.Event
  alias Core.EventManagerRepo
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.Repo
  alias OpsScheduler.Jobs.MedicationDispensesTerminator

  test "run/0" do
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)
    %{id: id} = insert(:medication_dispense, inserted_at: inserted_at)
    assert 1 == count_by_status(MedicationDispense.status(:new))

    MedicationDispensesTerminator.run()
    assert 0 == count_by_status(MedicationDispense.status(:new))
    assert 1 == count_by_status(MedicationDispense.status(:expired))
    assert [event] = EventManagerRepo.all(Event)

    assert %Event{
             entity_type: "MedicationDispense",
             entity_id: ^id,
             event_type: "StatusChangeEvent",
             properties: %{"status" => %{"new_value" => "EXPIRED"}}
           } = event
  end

  defp count_by_status(status) do
    MedicationDispense
    |> where([md], md.status == ^status)
    |> select([md], count(md.id))
    |> Repo.one()
  end
end
