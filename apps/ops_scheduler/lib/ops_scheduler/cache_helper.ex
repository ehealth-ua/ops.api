defmodule OpsScheduler.CacheHelper do
  @moduledoc false

  alias Core.Redis
  require Logger

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @spec get_entity_pipeline(integer, (map -> binary), (() -> Ecto.Query.t())) :: list()
  def get_entity_pipeline(ttl, key_resolver, query_resolver) do
    query_resolver.()
    |> @read_repo.all()
    |> Enum.map(fn %{count: count} = entity_data ->
      cache_key = key_resolver.(Map.delete(entity_data, :count))
      ["SETEX", cache_key, ttl, Redis.encode(count)]
    end)
  end

  @spec update_cache(list) :: :ok | {:error, any}
  def update_cache(pipeline_data) do
    pipeline_data
    |> Redis.pipeline()
    |> check_update_result()
  end

  defp check_update_result({:ok, update_result}) do
    update_result
    |> Enum.reject(&(&1 == "OK"))
    |> case do
      [] ->
        :ok

      [error | _] ->
        Logger.error("Partially failed to update count cache with error: `#{inspect(error)}`")
        {:error, error}
    end
  end

  defp check_update_result(error) do
    Logger.error("Failed to update count cache with error: `#{inspect(error)}`")
    error
  end
end
