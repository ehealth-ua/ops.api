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
    with {:ok, _} <- Declarations.terminate_declarations(attrs) do
      :ok
    else
      {:error, %Changeset{} = changeset} ->
        errors =
          Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        Logger.error("failed to deactivate declarations with: #{inspect(errors)}")

      {:error, reason} ->
        Logger.error("failed to deactivate declarations with: #{inspect(reason)}")
    end
  rescue
    e ->
      Logger.error("failed to deactivate declarations with: #{inspect(e)}")
  end

  def consume(value) do
    Logger.warn(fn -> "unknown kafka event: #{inspect(value)}" end)
    :ok
  end
end
