defmodule Core.EventManager do
  @moduledoc false

  alias Core.EventManager.Event
  alias Core.EventManagerRepo, as: Repo

  @type_change_status "StatusChangeEvent"

  def insert_change_status(_entity, status, status, _user_id), do: nil

  def insert_change_status(entity, _, status, user_id) do
    insert_change_status(entity, status, user_id)
  end

  def insert_change_status(entity, new_status, user_id) do
    entity_type =
      entity.__struct__
      |> to_string()
      |> String.split(".")
      |> List.last()

    Repo.insert(%Event{
      event_type: @type_change_status,
      entity_type: entity_type,
      entity_id: entity.id,
      properties: %{"status" => %{"new_value" => new_status}},
      event_time: NaiveDateTime.utc_now(),
      changed_by: user_id
    })
  end
end
