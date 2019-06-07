defmodule OpsScheduler.Jobs.CacheMedicationRequestsCountJobTest do
  @moduledoc false

  use Core.DataCase

  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.UUID
  alias OpsScheduler.Jobs.CacheMedicationRequestsCountJob
  alias Core.Redis

  @status_active MedicationRequest.status(:active)
  @status_completed MedicationRequest.status(:completed)
  @status_rejected MedicationRequest.status(:rejected)

  setup :verify_on_exit!

  test "run/0" do
    legal_entity_id1 = UUID.generate()
    legal_entity_id2 = UUID.generate()
    legal_entity_id3 = UUID.generate()
    legal_entity_id4 = UUID.generate()

    insert(:medication_request, legal_entity_id: legal_entity_id1)
    insert_list(10, :medication_request, legal_entity_id: legal_entity_id1, status: @status_completed)

    insert_list(2, :medication_request, legal_entity_id: legal_entity_id2, status: @status_active)
    insert_list(4, :medication_request, legal_entity_id: legal_entity_id3, status: @status_completed)
    insert_list(8, :medication_request, legal_entity_id: legal_entity_id4, status: @status_rejected)

    Redis.flush()
    CacheMedicationRequestsCountJob.run()

    get_count = &Redis.get(MedicationRequests.get_cache_key(&1))

    assert {:ok, 11} == get_count.(%{legal_entity_id: legal_entity_id1})
    assert {:ok, 2} == get_count.(%{legal_entity_id: legal_entity_id2, status: @status_active})
    assert {:ok, 4} == get_count.(%{legal_entity_id: legal_entity_id3, status: @status_completed})
    assert {:ok, 8} == get_count.(%{legal_entity_id: legal_entity_id4, status: @status_rejected})
  end
end
