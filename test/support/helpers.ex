defmodule OPS.Test.Helpers do
  @moduledoc false

  alias OPS.BlockRepo
  alias OPS.Block.Schema, as: Block

  def insert_initial_block do
    {:ok, block_start, 0} = DateTime.from_iso8601("1970-01-01T00:00:00Z")
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
