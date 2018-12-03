defmodule Core.Declarations.DeclarationStatusHistory do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  schema "declarations_status_hstr" do
    field(:declaration_id, UUID)
    field(:status, :string)

    timestamps(type: :utc_datetime, updated_at: false)
  end
end
