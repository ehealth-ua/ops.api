defmodule OPS.Seed.Schema do
  @primary_key false
  schema "seeds" do
    field :hash, Ecto.UUID
    field :inserted_at, :date

    timestamps(updated_at: false, type: :utc_datetime)
  end
end
