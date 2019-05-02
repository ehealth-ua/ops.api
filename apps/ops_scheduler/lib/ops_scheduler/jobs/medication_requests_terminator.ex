defmodule OpsScheduler.Jobs.MedicationRequestsTerminator do
  @moduledoc false

  use Confex, otp_app: :ops_scheduler
  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Repo
  alias Ecto.Multi
  import Ecto.Query
  require Logger

  def run do
    termination_batch_size = config()[:termination_batch_size]

    Logger.info("terminate all medication requests with ended_at <= today()")

    subquery =
      MedicationRequest
      |> where([mr], mr.status == ^MedicationRequest.status(:active))
      |> where([mr], mr.ended_at <= ^Date.utc_today())
      |> limit(^termination_batch_size)

    query =
      MedicationRequest
      |> join(:inner, [m], mr in subquery(subquery), on: m.id == mr.id)
      |> select([mr], [:id, :status, :updated_by])

    new_status = MedicationRequest.status(:expired)
    author_id = Confex.fetch_env!(:core, :system_user)

    updates = [
      status: new_status,
      updated_by: author_id,
      updated_at: DateTime.utc_now()
    ]

    Multi.new()
    |> Multi.update_all(:medication_requests, query, set: updates)
    |> Multi.run(:insert_events, &MedicationRequests.insert_events(&1, &2, new_status, author_id))
    |> Multi.run(:logged_terminations, &MedicationRequests.log_changes/2)
    |> Repo.transaction()
    |> handle_update_result()
  end

  defp handle_update_result({:ok, %{medication_requests: {0, _}}}), do: :ok
  defp handle_update_result({:ok, _}), do: run()
end
