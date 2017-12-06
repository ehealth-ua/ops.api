defmodule OPS.MedicationDispensesTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias OPS.MedicationDispenses.MedicationDispense
  alias OPS.MedicationDispenses
  alias OPS.MedicationDispenseStatusHistory
  alias OPS.EventManagerRepo
  alias OPS.EventManager.Event
  alias OPS.Repo

  test "terminate/1" do
    %{id: id} = insert(:medication_dispense)
    assert 1 == count_by_status(MedicationDispense.status(:new))

    MedicationDispenses.terminate(0)
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

  test "status history" do
    assert 0 == count_history()
    medication_dispense = insert(:medication_dispense)
    assert 1 == count_history()

    medication_dispense_history =
      MedicationDispenseStatusHistory
      |> Repo.all()
      |> hd()
    assert %{status: "NEW"} = medication_dispense_history

    medication_dispense
    |> cast(%{"status": "REJECTED"}, ~w(status)a)
    |> Repo.update!
    assert 2 == count_history()

    medication_dispense_history =
      MedicationDispenseStatusHistory
      |> Repo.all()
      |> List.last()
    assert %{status: "REJECTED"} = medication_dispense_history
  end

  defp count_history do
    MedicationDispenseStatusHistory
    |> select([mdh], count(mdh.id))
    |> Repo.one
  end

  defp count_by_status(status) do
    MedicationDispense
    |> where([md], md.status == ^status)
    |> select([md], count(md.id))
    |> Repo.one
  end
end
