defmodule Core.VerificationFailure do
  @moduledoc false

  alias Core.Block
  use Ecto.Schema

  schema "verification_failures" do
    field(:resolved, :boolean)

    belongs_to(:block, Block, foreign_key: :block_id)

    timestamps(type: :utc_datetime)
  end
end
