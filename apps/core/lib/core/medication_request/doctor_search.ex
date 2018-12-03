defmodule Core.MedicationRequest.DoctorSearch do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID
  alias Ecto.UUIDsList

  @primary_key false
  schema "medication_request_doctor_search" do
    field(:id, UUID)
    field(:legal_entity_id, UUID)
    field(:employee_id, UUIDsList)
    field(:person_id, UUID)
    field(:status, :string)
    field(:request_number, :string)
    field(:created_from, :date)
    field(:created_to, :date)
    field(:medication_id, UUID)
  end
end
