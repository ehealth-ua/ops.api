defmodule Core.EventManager.Event do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "events" do
    field(:event_type, :string)
    field(:entity_type, :string)
    field(:entity_id, UUID)
    field(:properties, :map)
    field(:event_time, :naive_datetime)
    field(:changed_by, UUID)

    timestamps()
  end
end
