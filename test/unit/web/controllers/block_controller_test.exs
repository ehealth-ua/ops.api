defmodule OPS.Web.BlockControllerTest do
  use OPS.Web.ConnCase

  alias OPS.BlockRepo
  alias OPS.Block.API, as: BlockAPI
  alias OPS.Block.Schema, as: Block

  setup %{conn: conn} do
    insert_initial_block()

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "gets latest block", %{conn: conn} do
    {:ok, block} = BlockAPI.close_block()

    assert 2 = BlockRepo.one(from b in Block, select: count(1))

    conn = get conn, "/latest_block"

    %{
      "block_start" => block_start,
      "block_end" => block_end,
      "hash" => hash,
      "inserted_at" => inserted_at
    } = json_response(conn, 200)["data"]

    assert ^block_start = DateTime.to_iso8601(block.block_start)
    assert ^block_end = DateTime.to_iso8601(block.block_end)
    assert ^hash = block.hash
    assert ^inserted_at = DateTime.to_iso8601(block.inserted_at)
  end
end
