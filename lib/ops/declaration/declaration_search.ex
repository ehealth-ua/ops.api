defmodule OPS.Declarations.DeclarationSearch do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "declarations_search" do
    field(:employee_id, Ecto.UUID)
    field(:person_id, Ecto.UUID)
    field(:legal_entity_id, Ecto.UUID)
    field(:division_id, Ecto.UUID)
    field(:status, :string)
    field(:is_active, :boolean)
  end
end
