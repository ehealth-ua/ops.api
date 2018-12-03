defmodule OpsScheduler.Jobs.MedicationRequestsTerminatorTest do
  @moduledoc false

  use Core.DataCase
  alias Core.EventManager.Event
  alias Core.EventManagerRepo
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Repo
  alias OpsScheduler.Jobs.MedicationRequestsTerminator

  test "run/0" do
    %{id: id} = insert(:medication_request, ended_at: "2017-01-01")

    assert 1 == count_by_status(MedicationRequest.status(:active))

    MedicationRequestsTerminator.run()

    assert 0 == count_by_status(MedicationRequest.status(:active))
    assert 1 == count_by_status(MedicationRequest.status(:expired))
    assert [event] = EventManagerRepo.all(Event)

    assert %Event{
             entity_type: "MedicationRequest",
             entity_id: ^id,
             event_type: "StatusChangeEvent",
             properties: %{"status" => %{"new_value" => "EXPIRED"}}
           } = event
  end

  defp count_by_status(status) do
    MedicationRequest
    |> where([mr], mr.status == ^status)
    |> select([mr], count(mr.id))
    |> Repo.one()
  end
end
