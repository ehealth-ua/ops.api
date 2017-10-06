defmodule OPS.MedicationRequests.MedicationRequestStatusHistory do
  @moduledoc false
  use Ecto.Schema

  schema "medication_requests_status_hstr" do
    field :medication_request_id, Ecto.UUID
    field :status, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
