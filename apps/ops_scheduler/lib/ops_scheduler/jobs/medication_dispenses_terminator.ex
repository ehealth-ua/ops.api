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

    Logger.info("terminate all medication dispenses with inserted_at + #{expiration} minutes < now()")

    query =
      MedicationDispense
      |> where([md], md.status == ^MedicationDispense.status(:new))
      |> where([md], md.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^(-expiration), "minute"))

    new_status = MedicationDispense.status(:expired)
    author_id = Confex.fetch_env!(:core, :system_user)

    updates = [
      status: new_status,
      updated_at: DateTime.utc_now(),
      updated_by: author_id
    ]

    Multi.new()
    |> Multi.update_all(:medication_dispenses, query, [set: updates], returning: [:id, :status, :updated_by])
    |> Multi.run(:insert_events, &MedicationDispenses.insert_events(&1, new_status, author_id))
    |> Multi.run(:logged_terminations, &MedicationDispenses.log_changes(&1))
    |> Repo.transaction()
  end
end
