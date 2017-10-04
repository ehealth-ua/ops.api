defmodule OPS.Block.Schema do
  @moduledoc false

  alias OPS.VerificationFailure.Schema, as: VerificationFailure

  use Ecto.Schema

  schema "blocks" do
    field :hash, :string
    field :block_start, :utc_datetime
    field :block_end, :utc_datetime
    field :version, :string

    has_many :verification_failures, VerificationFailure, foreign_key: :block_id

    timestamps(updated_at: false, type: :utc_datetime)
  end
end
