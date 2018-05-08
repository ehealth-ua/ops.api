defmodule OPS.MedicationRequest.DoctorSearch do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUIDsList

  @primary_key false
  schema "medication_request_doctor_search" do
    field(:id, Ecto.UUID)
    field(:legal_entity_id, Ecto.UUID)
    field(:employee_id, UUIDsList)
    field(:person_id, Ecto.UUID)
    field(:status, :string)
    field(:request_number, :string)
    field(:created_from, :date)
    field(:created_to, :date)
    field(:medication_id, Ecto.UUID)
  end
end
