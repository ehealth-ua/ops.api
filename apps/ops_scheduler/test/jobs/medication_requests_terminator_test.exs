defmodule OpsScheduler.Jobs.MedicationRequestsTerminatorTest do
  @moduledoc false
  use Core.DataCase
  import Mox

  alias Core.MedicationRequests.MedicationRequest
  alias Core.Repo
  alias OpsScheduler.Jobs.MedicationRequestsTerminator
  setup :verify_on_exit!

  test "run/0" do
    expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
    insert(:medication_request, ended_at: "2017-01-01")
    assert 1 == count_by_status(MedicationRequest.status(:active))
    MedicationRequestsTerminator.run()
    assert 0 == count_by_status(MedicationRequest.status(:active))
    assert 1 == count_by_status(MedicationRequest.status(:expired))
  end

  defp count_by_status(status) do
    MedicationRequest
    |> where([mr], mr.status == ^status)
    |> select([mr], count(mr.id))
    |> Repo.one()
  end
end
