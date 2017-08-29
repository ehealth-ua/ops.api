defmodule OPS.DeclarationAutoApprove do
  @moduledoc """
  Process responsible for auto approve declarations
  Process runs once per day, in the night from 21 to 4 UTC
  """

  use GenServer

  alias OPS.API.IL

  import OPS.Declarations, only: [approve_declarations: 2]

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
    {:ok, schedule_next_run(ms)}
  end

  def handle_cast({:approve, ms}, _) do
    with {:ok, response} <- IL.get_global_parameters(),
         parameters <- Map.fetch!(response, "data"),
         unit <- Map.fetch!(parameters, "verification_request_term_unit"),
         expiration <- Map.fetch!(parameters, "verification_request_expiration")
    do
      approve_declarations(expiration, normalize_unit(unit))
    end
    {:noreply, schedule_next_run(ms)}
  end

  def approve_msg(ms), do: {:"$gen_cast", {:approve, ms}}

  defp normalize_unit(unit) do
    unit
    |> String.downcase
    |> String.replace_trailing("s", "")
  end

  defp validate_time(hour, {from, to}), do: hour >= from && hour <= to

  defp schedule_next_run(ms) do
    unless Application.get_env(:ops, :env) == :test do
      Process.send_after(self(), approve_msg(ms), ms)
    end
  end
end
