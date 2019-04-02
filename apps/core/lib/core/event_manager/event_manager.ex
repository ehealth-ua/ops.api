defmodule Core.EventManager do
  @moduledoc false

  @type_change_status "StatusChangeEvent"
  @producer Application.get_env(:core, :kafka)[:producer]

  def publish_change_status(_entity, status, status, _user_id), do: nil

  def publish_change_status(entity, _, status, user_id) do
    publish_change_status(entity, status, user_id)
  end

  def publish_change_status(entity, new_status, user_id) do
    event = %{
      event_type: @type_change_status,
      entity_type: entity_type(entity),
      entity_id: entity.id,
      properties: %{"status" => %{"new_value" => new_status}},
      event_time: DateTime.utc_now(),
      changed_by: user_id
    }

    publish_event(event)
  end

  def publish_change_statuses([], _new_status, _user_id), do: :ok

  def publish_change_statuses(entities, new_status, user_id) do
    Enum.each(entities, fn entity ->
      event = %{
        event_type: @type_change_status,
        entity_type: entity_type(entity),
        entity_id: entity.id,
        properties: %{"status" => %{"new_value" => new_status}},
        event_time: DateTime.utc_now(),
        changed_by: user_id,
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }

      publish_event(event)
    end)
  end

  defp entity_type(entity) do
    entity.__struct__
    |> Module.split()
    |> List.last()
  end

  defp publish_event(event) do
    with :ok <- @producer.publish_to_event_manager(event), do: {:ok, event}
  end
end
