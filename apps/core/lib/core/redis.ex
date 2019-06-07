defmodule Core.Redis do
  @moduledoc false

  @key_prefix "ops"

  use Confex, otp_app: :core
  require Logger

  def get(key) when is_binary(key) do
    with {:ok, encoded_value} <- command(["GET", key]) do
      if encoded_value == nil do
        {:error, :not_found}
      else
        {:ok, decode(encoded_value)}
      end
    else
      {:error, reason} = error ->
        Logger.error("Failed to get value by key (#{key}) with error #{inspect(reason)}")
        error
    end
  end

  def get_lazy(key, ttl, fun) do
    with {:ok, value} <- get(key) do
      {:ok, value}
    else
      {:error, :not_found} ->
        with value when value != nil <- fun.(),
             :ok <- setex(key, ttl, value) do
          {:ok, value}
        end

      error ->
        error
    end
  end

  def setex(key, ttl_seconds, value) when is_binary(key) and is_integer(ttl_seconds) and value != nil do
    do_set(["SETEX", key, ttl_seconds, encode(value)])
  end

  def delete(key) do
    do_set(["DEL", key])
  end

  def flush do
    do_set(["FLUSHDB"])
  end

  defp command(command) when is_list(command) do
    Redix.command(get_connection_id(), command)
  end

  defp do_set(params) do
    case command(params) do
      {:ok, _} ->
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to set with params #{inspect(params)} with error #{inspect(reason)}")
        error
    end
  end

  def pipeline([]), do: {:ok, []}

  def pipeline(commands) when is_list(commands) do
    Redix.pipeline(get_connection_id(), commands)
  end

  def create_cache_key(key, %{} = params) do
    cache_key =
      Enum.reduce(params, key, fn
        {k, v}, acc when is_list(v) -> "#{acc}_#{k}_#{Enum.sort(v)}"
        {k, v}, acc -> "#{acc}_#{k}_#{v}"
      end)

    encrypted_cache_key = :md5 |> :crypto.hash(cache_key) |> Base.encode64()

    "#{@key_prefix}:#{key}:#{encrypted_cache_key}"
  end

  def encode(value), do: :erlang.term_to_binary(value)

  defp decode(value), do: :erlang.binary_to_term(value)

  defp get_connection_id do
    pool_size = config()[:pool_size]
    connection_index = Enum.random(0..(pool_size - 1))
    String.to_atom("redis_#{connection_index}")
  end
end
