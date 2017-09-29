defmodule OPS.GeneratingSeedsTest do
  @moduledoc false

  use OPS.DataCase

  alias OPS.Block.API, as: BlockAPI

  setup do
    {:ok, initial_block} = insert_initial_block()

    {:ok, %{initial_hash: initial_block.hash}}
  end

  test "start init genserver", %{initial_hash: first_hash} do
    d1 = insert(:declaration, seed: first_hash)
    d2 = insert(:declaration, seed: first_hash)
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, %{hash: second_hash}} = BlockAPI.close_block()

    d3 = insert(:declaration, seed: second_hash)
    d4 = insert(:declaration, seed: second_hash)
    assert second_hash == d3.seed
    assert second_hash == d4.seed

    {:ok, %{hash: _third_hash}} = BlockAPI.close_block()

    :ok = BlockAPI.verify_chain()
  end

  test "a modification to block is detected", %{initial_hash: first_hash} do
    d1 = insert(:declaration, seed: first_hash)
    d2 = insert(:declaration, seed: first_hash)
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, block} = BlockAPI.close_block()

    {:ok, _} = Repo.update(Ecto.Changeset.change(d1, %{employee_id: "0bea8aed-9f41-44f9-a3cf-43ac221d2f1a"}))

    {:error, [%{block: ^block, reconstructed_hash: _malformed_hash}]} = BlockAPI.verify_chain()
  end

  test "an addition to block is detected", %{initial_hash: first_hash} do
    d1 = insert(:declaration, seed: first_hash)
    d2 = insert(:declaration, seed: first_hash)
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, block} = BlockAPI.close_block()

    insert(:declaration, seed: first_hash, inserted_at: d1.inserted_at)

    {:error, [%{block: ^block, reconstructed_hash: _malformed_hash}]} = BlockAPI.verify_chain()
  end

  test "a deletion from block is detected", %{initial_hash: first_hash} do
    d1 = insert(:declaration, seed: first_hash)
    d2 = insert(:declaration, seed: first_hash)
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, block} = BlockAPI.close_block()

    {:ok, _} = Repo.delete(d2)

    {:error, [%{block: ^block, reconstructed_hash: _malformed_hash}]} = BlockAPI.verify_chain()
  end

  @tag :pending
  test "each block is verified using its own algorithm's version", %{initial_hash: first_hash} do
    d1 = insert(:declaration, seed: first_hash)
    d2 = insert(:declaration, seed: first_hash)
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, v1_block} = BlockAPI.close_block()

    d1 = insert(:declaration, seed: v1_block.hash)
    d2 = insert(:declaration, seed: v1_block.hash)
    assert v1_block.hash == d1.seed
    assert v1_block.hash == d2.seed

    {:ok, v2_block} = BlockAPI.close_block()

    :ok = BlockAPI.verify_chain()
  end
end
