defmodule OpsScheduler.Jobs.MedicationRequestsTerminatorTest do
  @moduledoc false
  use Core.DataCase
  import Mox

  alias Core.MedicationRequests.MedicationRequest
  alias Core.Repo
  alias OpsScheduler.Jobs.MedicationRequestsTerminator
  setup :verify_on_exit!

  test "run/0" do
    termination_batch_size = Application.get_env(:ops_scheduler, MedicationRequestsTerminator)[:termination_batch_size]
    terminate_count = termination_batch_size * 2 + 1
    expect(KafkaMock, :publish_to_event_manager, terminate_count, fn _ -> :ok end)
    ended_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :second)
    Enum.each(1..terminate_count, fn _ -> insert(:medication_request, ended_at: ended_at) end)
    assert terminate_count == count_by_status(MedicationRequest.status(:active))
    MedicationRequestsTerminator.run()
    assert 0 == count_by_status(MedicationRequest.status(:active))
    assert terminate_count == count_by_status(MedicationRequest.status(:expired))
  end

  defp count_by_status(status) do
    MedicationRequest
    |> where([mr], mr.status == ^status)
    |> select([mr], count(mr.id))
    |> Repo.one()
  end
end
