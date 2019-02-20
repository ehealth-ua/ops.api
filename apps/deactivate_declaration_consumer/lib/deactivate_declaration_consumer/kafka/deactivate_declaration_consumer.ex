defmodule DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumer do
  @moduledoc false

  use KafkaEx.GenConsumer
  alias Core.Declarations
  alias Ecto.Changeset
  alias KafkaEx.Protocol.Fetch.Message
  require Logger

  def handle_message_set(message_set, state) do
    for %Message{value: message, offset: offset} <- message_set do
      value = :erlang.binary_to_term(message)
      Logger.debug(fn -> "message: " <> inspect(value) end)
      Logger.info(fn -> "offset: #{offset}" end)
      :ok = consume(value)
    end

    {:async_commit, state}
  end

  def consume(%{"actor_id" => _} = attrs) do
    Declarations.chunk_terminate_declarations(attrs, 100)
  rescue
    e ->
      Logger.error("failed to deactivate declarations with: #{inspect(e)}")
      :error
  end

  def consume(value) do
    Logger.warn(fn -> "unknown kafka event: #{inspect(value)}" end)
    :ok
  end
end
