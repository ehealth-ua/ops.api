defmodule OpsScheduler.Jobs.MedicationDispensesTerminator do
  @moduledoc false

  use Confex, otp_app: :ops_scheduler
  alias Core.MedicationDispenses
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.Repo
  alias Ecto.Multi
  import Ecto.Query
  require Logger

  def run do
    expiration = config()[:expiration]
    termination_batch_size = config()[:termination_batch_size]

    Logger.info("terminate medication dispenses with inserted_at + #{expiration} minutes < now()")

    subquery =
      MedicationDispense
      |> where([md], md.status == ^MedicationDispense.status(:new))
      |> where([md], md.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^(-expiration), "minute"))
      |> limit(^termination_batch_size)

    query =
      MedicationDispense
      |> join(:inner, [m], md in subquery(subquery), on: m.id == md.id)
      |> select([md], [:id, :status, :updated_by])

    new_status = MedicationDispense.status(:expired)
    author_id = Confex.fetch_env!(:core, :system_user)

    updates = [
      status: new_status,
      updated_at: DateTime.utc_now(),
      updated_by: author_id
    ]

    Multi.new()
    |> Multi.update_all(:medication_dispenses, query, set: updates)
    |> Multi.run(:insert_events, &MedicationDispenses.insert_events(&1, &2, new_status, author_id))
    |> Multi.run(:logged_terminations, &MedicationDispenses.log_changes/2)
    |> Repo.transaction()
    |> handle_update_result()
  end

  defp handle_update_result({:ok, %{medication_dispenses: {0, _}}}), do: :ok
  defp handle_update_result({:ok, _}), do: run()
end
