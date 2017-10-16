defmodule OPS.MedicationRequest.PersonSearch do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_request_person_search" do
    field :person_id, Ecto.UUID
  end
end
