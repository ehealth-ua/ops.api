defmodule OPS.GeneratingSeedsTest do
  @moduledoc false

  use OPS.DataCase

  alias OPS.Block.API, as: BlockAPI

  test "start init genserver" do
    {:ok, %{hash: first_hash}} = BlockAPI.close_block(~D[2014-01-01])

    d1 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 01:00:00])
    d2 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 02:00:00])
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, %{hash: second_hash}} = BlockAPI.close_block(~D[2014-01-02])

    d3 = insert(:declaration, seed: second_hash, inserted_at: ~N[2014-01-03 01:00:00])
    d4 = insert(:declaration, seed: second_hash, inserted_at: ~N[2014-01-03 02:00:00])
    assert second_hash == d3.seed
    assert second_hash == d4.seed

    {:ok, %{hash: _third_hash}} = BlockAPI.close_block(~D[2014-01-03])

    :ok = BlockAPI.verify_chain()
  end

  test "a modification to block is detected" do
    {:ok, %{hash: first_hash}} = BlockAPI.close_block(~D[2014-01-01])

    d1 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 01:00:00])
    d2 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 02:00:00])
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, %{hash: second_hash}} = BlockAPI.close_block(~D[2014-01-02])

    {:ok, _} = Repo.update(Ecto.Changeset.change(d1, %{employee_id: "0bea8aed-9f41-44f9-a3cf-43ac221d2f1a"}))

    {:error, {~D[2014-01-02], ^second_hash, _malformed_hash}} = BlockAPI.verify_chain()
  end

  test "an addition to block is detected" do
    {:ok, %{hash: first_hash}} = BlockAPI.close_block(~D[2014-01-01])

    d1 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 01:00:00])
    d2 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 02:00:00])
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, %{hash: second_hash}} = BlockAPI.close_block(~D[2014-01-02])

    insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 03:00:00])

    {:error, {~D[2014-01-02], ^second_hash, _malformed_hash}} = BlockAPI.verify_chain()
  end

  test "a deletion from block is detected" do
    {:ok, %{hash: first_hash}} = BlockAPI.close_block(~D[2014-01-01])

    d1 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 01:00:00])
    d2 = insert(:declaration, seed: first_hash, inserted_at: ~N[2014-01-02 02:00:00])
    assert first_hash == d1.seed
    assert first_hash == d2.seed

    {:ok, %{hash: second_hash}} = BlockAPI.close_block(~D[2014-01-02])

    {:ok, _} = Repo.delete(d2)

    {:error, {~D[2014-01-02], ^second_hash, _malformed_hash}} = BlockAPI.verify_chain()
  end
end
