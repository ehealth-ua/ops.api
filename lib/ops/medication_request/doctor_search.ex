defmodule OPS.MedicationRequest.DoctorSearch do
  @moduledoc false

  use Ecto.Schema
  alias OPS.Ecto.UUIDsList

  @primary_key false
  schema "medication_request_doctor_search" do
    field :id, Ecto.UUID
    field :employee_id, UUIDsList
    field :person_id, Ecto.UUID
    field :status, :string
  end
end
