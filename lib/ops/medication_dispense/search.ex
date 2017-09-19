defmodule OPS.MedicationDispense.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_dispense_search" do
    field :id, Ecto.UUID
    field :medication_request_id, Ecto.UUID
    field :legal_entity_id, Ecto.UUID
    field :division_id, Ecto.UUID
    field :status, :string
    field :is_active, :boolean
  end
end
