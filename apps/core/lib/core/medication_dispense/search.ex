defmodule Core.MedicationDispense.Search do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key false
  schema "medication_dispense_search" do
    field(:id, UUID)
    field(:medication_request_id, UUID)
    field(:legal_entity_id, UUID)
    field(:division_id, UUID)
    field(:status, :string)
    field(:is_active, :boolean)
    field(:dispensed_from, :date)
    field(:dispensed_to, :date)
  end
end
