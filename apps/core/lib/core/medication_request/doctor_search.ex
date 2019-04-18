defmodule Core.MedicationRequest.DoctorSearch do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key false
  schema "medication_request_doctor_search" do
    field(:id, UUID)
    field(:employee_id, :string)
    field(:legal_entity_id, UUID)
    field(:person_id, UUID)
    field(:status, :string)
    field(:request_number, :string)
    field(:created_from, :date)
    field(:created_to, :date)
    field(:medication_id, UUID)
    field(:intent, :string)
  end
end
