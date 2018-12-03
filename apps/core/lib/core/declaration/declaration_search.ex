defmodule Core.Declarations.DeclarationSearch do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key false
  embedded_schema do
    field(:employee_id, UUID)
    field(:person_id, UUID)
    field(:legal_entity_id, UUID)
    field(:division_id, UUID)
    field(:status, :string)
    field(:is_active, :boolean)
    field(:start_year, :integer)
    field(:declaration_number, :string)
  end
end
