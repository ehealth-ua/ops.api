defmodule Core.MedicationRequest.Search do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key false
  schema "medication_request_search" do
    field(:id, UUID)
    field(:employee_id, :string)
    field(:legal_entity_id, UUID)
    field(:person_id, UUID)
    field(:status, :string)
    field(:request_number, :string)
    field(:created_at, :date)
    field(:division_id, :string)
    field(:medication_id, :string)
    field(:medical_program_id, UUID)
    field(:is_active, :boolean)
    field(:started_at_to, :date)
  end
end
