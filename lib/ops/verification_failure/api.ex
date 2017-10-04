defmodule OPS.VerificationFailure.API do
  @moduledoc false

  alias OPS.BlockRepo
  alias OPS.VerificationFailure.Schema, as: VerificationFailure

  def mark_as_mangled!(block) do
    BlockRepo.insert! %VerificationFailure{block_id: block.id}
  end
end
