defmodule OpsScheduler.Jobs.CacheMedicationRequestsCountJob do
  @moduledoc false

  import Ecto.Query
  import OpsScheduler.CacheHelper

  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest

  def run do
    ttl = Confex.fetch_env!(:core, :cache)[:list_medication_requests_ttl]

    legal_entity_pipeline =
      get_entity_pipeline(ttl, &MedicationRequests.get_cache_key/1, fn ->
        MedicationRequest
        |> group_by([:legal_entity_id])
        |> select([d], %{legal_entity_id: d.legal_entity_id, count: count(d.id)})
      end)

    legal_entity_status_pipeline =
      get_entity_pipeline(ttl, &MedicationRequests.get_cache_key/1, fn ->
        MedicationRequest
        |> group_by([:status, :legal_entity_id])
        |> select([d], %{legal_entity_id: d.legal_entity_id, status: d.status, count: count(d.id)})
      end)

    update_cache(legal_entity_pipeline ++ legal_entity_status_pipeline)
  end
end
