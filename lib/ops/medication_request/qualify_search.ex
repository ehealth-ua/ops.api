defmodule OPS.MedicationRequest.QualifySearch do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_request_qualify_search" do
    field :person_id, Ecto.UUID
    field :started_at, :date
    field :ended_at, :date
  end
end
