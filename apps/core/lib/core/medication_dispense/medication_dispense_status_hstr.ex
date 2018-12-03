defmodule Core.MedicationDispenseStatusHistory do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  schema "medication_dispense_status_hstr" do
    field(:medication_dispense_id, UUID)
    field(:status, :string)

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
