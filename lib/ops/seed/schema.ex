defmodule OPS.Seed.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "seeds" do
    field :hash, :binary

    timestamps(updated_at: false, type: :utc_datetime)
  end
end
