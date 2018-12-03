defmodule Core.VerificationFailure.API do
  @moduledoc false

  alias Core.BlockRepo
  alias Core.VerificationFailure

  def mark_as_mangled!(block) do
    BlockRepo.insert!(%VerificationFailure{block_id: block.id})
  end
end
