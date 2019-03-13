defmodule Core.Test.Helpers do
  @moduledoc false

  alias Core.Block
  alias Core.BlockRepo

  def insert_initial_block do
    block_start = DateTime.from_naive!(~N[1970-01-01 00:00:00.000000], "Etc/UTC")
    block_end = DateTime.utc_now()

    block = %Block{
      hash: "just_some_initially_put_hash",
      block_start: block_start,
      block_end: block_end,
      version: "v1"
    }

    BlockRepo.insert(block)
  end
end
