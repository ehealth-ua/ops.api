defmodule OPS.SendingNotificationTest do
  @moduledoc false

  use OPS.DataCase

  alias OPS.Block.API, as: BlockAPI

  describe "When chain is mangled" do
    defmodule IL do
      @moduledoc false

      use MicroservicesHelper

      Plug.Router.post "/internal/hash_chain/verification_failed" do
        %{
          "data" => [
            %{
              "block_id" => _,
              "original_hash" => _,
              "reconstructed_hash" => _
            }
          ]
        } = conn.params

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: "Notification has been received."}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(IL)

      System.put_env("IL_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("IL_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, initial_block} = insert_initial_block()

      {:ok, %{initial_hash: initial_block.hash}}
    end

    test "in case of mangled hash chain - a notification is sent", %{initial_hash: first_hash} do
      d1 = insert(:declaration, seed: first_hash)
      d2 = insert(:declaration, seed: first_hash)
      assert first_hash == d1.seed
      assert first_hash == d2.seed

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

      {:ok, _block} = BlockAPI.close_block()
  
      assert :ok = BlockAPI.verify_chain_and_notify()
    end
  end
end
