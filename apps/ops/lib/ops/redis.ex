defmodule OPS.Redis do
  @moduledoc false

  require Logger
  use Confex, otp_app: :ops

  def get(key) when is_binary(key) do
    with {:ok, encoded_value} <- command(["GET", key]) do
      if encoded_value == nil do
        {:error, :not_found}
      else
        {:ok, decode(encoded_value)}
      end
    else
      {:error, reason} = err ->
        Logger.error("Failed to get value by key (#{key}) with error #{inspect(reason)}")
        err
    end
  end

  def setex(key, ttl_seconds, value) when is_binary(key) and is_integer(ttl_seconds) and value != nil do
    do_set(["SETEX", key, ttl_seconds, encode(value)])
  end

  defp do_set(params) do
    case command(params) do
      {:ok, _} ->
        :ok

      {:error, reason} = err ->
        Logger.error("Failed to set with params #{inspect(params)} with error #{inspect(reason)}")
        err
    end
  end

  defp encode(value), do: :erlang.term_to_binary(value)

  defp decode(value), do: :erlang.binary_to_term(value)

  defp command(command) when is_list(command) do
    pool_size = config()[:pool_size]
    connection_index = Enum.random(0..pool_size)
    Redix.command(:"redis_#{connection_index}", command)
  end
end
