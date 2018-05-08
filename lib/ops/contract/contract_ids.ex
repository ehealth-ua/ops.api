defmodule OPS.Contracts.ContractIDs do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUIDsList

  @primary_key false
  embedded_schema do
    field(:ids, UUIDsList)
  end
end
