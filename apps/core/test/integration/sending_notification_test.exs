defmodule Core.SendingNotificationTest do
  @moduledoc false

  use Core.DataCase
  alias Core.Block.API, as: BlockAPI

  describe "When chain is mangled" do
    setup do
      {:ok, initial_block} = insert_initial_block()
      {:ok, %{initial_hash: initial_block.hash}}
    end

    test "in case of mangled hash chain - a notification is sent", %{initial_hash: first_hash} do
      d1 = insert(:declaration, seed: first_hash)
      d2 = insert(:declaration, seed: first_hash)
      assert first_hash == d1.seed
      assert first_hash == d2.seed

      expect(IlMock, :send_notification, fn _ -> {:ok, %{"data" => "Notification has been received."}} end)
      {:ok, _block} = BlockAPI.close_block()
      insert(:declaration, seed: first_hash, inserted_at: d1.inserted_at)

      assert {:ok, %{"data" => "Notification has been received."}} = BlockAPI.verify_chain_and_notify()
    end
  end

  describe "When chain is not mangled" do
    setup do
      {:ok, initial_block} = insert_initial_block()
      {:ok, %{initial_hash: initial_block.hash}}
    end

    test "in case of good hash chain - a notification is not sent", %{initial_hash: first_hash} do
      d1 = insert(:declaration, seed: first_hash)
      d2 = insert(:declaration, seed: first_hash)
      assert first_hash == d1.seed
      assert first_hash == d2.seed
      expect(IlMock, :send_notification, fn _ -> :ok end)
      {:ok, _block} = BlockAPI.close_block()

      assert :ok = BlockAPI.verify_chain_and_notify()
    end
  end
end
