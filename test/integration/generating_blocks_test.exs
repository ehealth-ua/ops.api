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

  test "each block is verified using its own algorithm's version", %{initial_hash: first_hash} do
    d1 = insert(:declaration, seed: first_hash)
    d2 = insert(:declaration, seed: first_hash)
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, v1_block} = BlockAPI.close_block()

    assert "v1" == v1_block.version

    d3 = insert(:declaration, seed: v1_block.hash)
    d4 = insert(:declaration, seed: v1_block.hash)
    assert v1_block.hash == d3.seed
    assert v1_block.hash == d4.seed

    new_query = "
      SELECT array_to_string(array_agg(id), '')
        FROM declarations
       WHERE inserted_at > $1 AND inserted_at <= $2
    "

    block_versions = Application.get_env(:ops, :block_versions)
    Application.put_env(:ops, :block_versions, Map.put_new(block_versions, "v2", new_query))
    Application.put_env(:ops, :current_block_version, "v2")

    {:ok, v2_block} = BlockAPI.close_block()

    d5 = insert(:declaration, seed: v2_block.hash)
    d6 = insert(:declaration, seed: v2_block.hash)

    assert "v2" == v2_block.version
    assert "#{d3.id}#{d4.id}" == v2_block.hash
    assert "#{d3.id}#{d4.id}" == d5.seed
    assert "#{d3.id}#{d4.id}" == d6.seed

    :ok = BlockAPI.verify_chain()
  end
end
