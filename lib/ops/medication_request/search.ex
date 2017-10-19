defmodule OPS.MedicationRequest.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_request_search" do
    field :id, Ecto.UUID
    field :employee_id, :string
    field :person_id, Ecto.UUID
    field :status, :string
    field :request_number, :string
    field :created_at, :date
    field :division_id, :string
    field :medication_id, :string
    field :is_active, :boolean
  end
end
