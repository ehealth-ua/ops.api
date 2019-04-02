defmodule Core.Kafka.Producer do
  @moduledoc false
  @event_manager_topic "event_manager_topic"

  @behaviour Core.Kafka.ProducerBehaviour

  require Logger

  def publish_to_event_manager(event) do
    case Kaffe.Producer.produce_sync(@event_manager_topic, 0, "", :erlang.term_to_binary(event)) do
      :ok ->
        :ok

      error ->
        Logger.warn("Published event #{inspect(event)} to kafka failed: #{inspect(error)}")
        error
    end
  end
end
