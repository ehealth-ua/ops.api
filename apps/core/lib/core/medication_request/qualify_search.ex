defmodule Core.MedicationRequest.QualifySearch do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key false
  schema "medication_request_qualify_search" do
    field(:person_id, UUID)
    field(:started_at, :date)
    field(:ended_at, :date)
  end
end
