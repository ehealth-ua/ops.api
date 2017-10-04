defmodule OPS.VerificationFailure.Schema do
  @moduledoc false

  alias OPS.Block.Schema, as: Block

  use Ecto.Schema

  schema "blocks" do
    field :resolved, :boolean

    belongs_to :block, Block

    timestamps(updated_at: false, type: :utc_datetime)
  end
end
