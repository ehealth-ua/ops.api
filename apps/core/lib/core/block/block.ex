defmodule Core.Block do
  @moduledoc false

  alias Core.VerificationFailure
  use Ecto.Schema

  schema "blocks" do
    field(:hash, :string)
    field(:block_start, :utc_datetime_usec)
    field(:block_end, :utc_datetime_usec)
    field(:version, :string)

    has_many(:verification_failures, VerificationFailure, foreign_key: :block_id)

    timestamps(updated_at: false, type: :utc_datetime_usec)
  end
end
