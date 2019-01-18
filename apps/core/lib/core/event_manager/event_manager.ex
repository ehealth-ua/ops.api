defmodule Core.EventManager do
  @moduledoc false

  alias Core.EventManager.Event
  alias Core.EventManagerRepo, as: Repo
  alias Ecto.UUID

  @type_change_status "StatusChangeEvent"

  def insert_change_status(_entity, status, status, _user_id), do: nil

  def insert_change_status(entity, _, status, user_id) do
    insert_change_status(entity, status, user_id)
  end

  def insert_change_status(entity, new_status, user_id) do
    type = entity_type(entity)

    Repo.insert(%Event{
      event_type: @type_change_status,
      entity_type: type,
      entity_id: entity.id,
      properties: %{"status" => %{"new_value" => new_status}},
      event_time: NaiveDateTime.utc_now(),
      changed_by: user_id
    })
  end

  def insert_change_statuses([], _new_status, _user_id), do: :ok

  def insert_change_statuses(entities, new_status, user_id) do
    events =
      Enum.map(entities, fn entity ->
        type = entity_type(entity)

        %{
          id: UUID.generate(),
          event_type: @type_change_status,
          entity_type: type,
          entity_id: entity.id,
          properties: %{"status" => %{"new_value" => new_status}},
          event_time: NaiveDateTime.utc_now(),
          changed_by: user_id,
          inserted_at: NaiveDateTime.utc_now(),
          updated_at: NaiveDateTime.utc_now()
        }
      end)

    Repo.insert_all(Event, events)
  end

  defp entity_type(entity) do
    entity.__struct__
    |> Module.split()
    |> List.last()
  end
end
