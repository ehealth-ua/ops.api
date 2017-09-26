defmodule OPS.Block.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "blocks" do
    field :hash, :string
    field :block_start, :utc_datetime
    field :block_end, :utc_datetime

    timestamps(updated_at: false, type: :utc_datetime)
  end
end
