defmodule OpsScheduler.Jobs.MedicationRequestsTerminator do
  @moduledoc false

  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Repo
  alias Ecto.Multi
  import Ecto.Query
  require Logger

  def run do
    Logger.info("terminate all medication requests with ended_at <= today()")

    query =
      MedicationRequest
      |> where([mr], mr.status == ^MedicationRequest.status(:active))
      |> where([mr], mr.ended_at <= ^Date.utc_today())

    new_status = MedicationRequest.status(:expired)
    author_id = Confex.fetch_env!(:core, :system_user)

    updates = [
      status: new_status,
      updated_by: author_id,
      updated_at: DateTime.utc_now()
    ]

    Multi.new()
    |> Multi.update_all(:medication_requests, query, [set: updates], returning: [:id, :status, :updated_by])
    |> Multi.run(:insert_events, &MedicationRequests.insert_events(&1, new_status, author_id))
    |> Multi.run(:logged_terminations, &MedicationRequests.log_changes(&1))
    |> Repo.transaction()
  end
end
