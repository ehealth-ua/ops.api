defmodule OPS.DeclarationTerminator do
  @moduledoc """
    Process responsible for termination declarations which achieved their end_date
    Process runs once per day, in the night from 21 to 4 UTC
  """

  use GenServer

  import OPS.Declarations, only: [terminate_declarations: 0]

  # Client API

  @config Confex.get_env(:ops, __MODULE__)

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  # Server API

  def init(_) do
    now = DateTime.to_time(DateTime.utc_now)
    {from, _to} = @config[:utc_interval]
    ms = if validate_time(now.hour, @config[:utc_interval]),
      do: @config[:frequency],
      else: abs(from - now.hour) * 60 * 60 * 1000
    {:ok, send(self(), terminate_msg(ms))}
  end

  def handle_cast({:terminate, ms}, _) do
    terminate_declarations()
    {:noreply, Process.send_after(self(), terminate_msg(@config[:frequency]), ms)}
  end

  def terminate_msg(ms), do: {:"$gen_cast", {:terminate, ms}}

  defp validate_time(hour, {from, to}), do: hour >= from && hour <= to
end
