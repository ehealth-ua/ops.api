defmodule DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumer do
  @moduledoc false

  alias Core.Declarations
  require Logger

  def handle_messages(messages) do
    for %{value: value, offset: offset} <- messages do
      value = :erlang.binary_to_term(value)
      Logger.debug(fn -> "message: " <> inspect(value) end)
      Logger.info(fn -> "offset: #{offset}" end)
      :ok = consume(value)
    end

    :ok
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
