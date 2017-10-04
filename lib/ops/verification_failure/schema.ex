defmodule OPS.VerificationFailure.Schema do
  @moduledoc false

  alias OPS.Block.Schema, as: Block

  use Ecto.Schema

  schema "verification_failures" do
    field :resolved, :boolean

    belongs_to :block, Block, foreign_key: :block_id

    timestamps(type: :utc_datetime)
  end
end
