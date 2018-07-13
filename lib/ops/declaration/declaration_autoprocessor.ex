defmodule OPS.DeclarationsAutoProcessor do
  @moduledoc """
  The boundary for the Declarations system
  """

  use OPS.Search
  use Confex, otp_app: :ops
  use GenServer

  import Ecto.{Query, Changeset}, warn: false
  alias OPS.Repo
  alias OPS.Declarations.Declaration
  alias OPS.Declarations
  require Logger

  @il_api Application.get_env(:ops, :api_resolvers)[:il]

  def approve_declarations do
    init_processor_state(:declaration_approver)
    GenServer.cast(:declaration_approver, {:approve, self()})
  end

  def terminate_declarations do
    init_processor_state(:declaration_terminator)
    GenServer.cast(:declaration_terminator, {:autoterminate, self()})
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:update_state, state}, _, _) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:approve, pid}, %{limit: limit} = state) do
    case do_approve_declarations(state) do
      {:ok, rows_updated} when rows_updated >= limit ->
        GenServer.cast(:declaration_approver, {:approve, pid})

      {:ok, _} ->
        send(pid, :approve)

      error ->
        Logger.error("Declarations was not approved: #{inspect(error)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:autoterminate, pid}, %{limit: limit} = state) do
    case do_terminate_declarations(state) do
      {:ok, rows_updated} when rows_updated >= limit ->
        GenServer.cast(:declaration_terminator, {:autoterminate, pid})

      {:ok, _} ->
        send(pid, :autoterminate)

      error ->
        Logger.error("Declarations was not terminated: #{inspect(error)}")
    end

    {:noreply, state}
  end

  def init_processor_state(gen_server) do
    user_id = Confex.fetch_env!(:ops, :system_user)
    limit = config()[:termination_batch_size]

    with {:ok, response} <- @il_api.get_global_parameters(),
         _ <- Logger.info("Global parameters: #{Poison.encode!(response)}"),
         parameters <- Map.fetch!(response, "data"),
         unit <- Map.fetch!(parameters, "verification_request_term_unit"),
         expiration <- parameters |> Map.fetch!("verification_request_expiration") |> String.to_integer(),
         unit =
           unit
           |> String.downcase()
           |> String.replace_trailing("s", ""),
         state = %{unit: unit, expiration: expiration, limit: limit, user_id: user_id},
         :ok <- GenServer.call(gen_server, {:update_state, state}) do
      :ok
    else
      error -> Logger.error("Can't start declaration schelder! #{inspect(error)}")
    end
  end

  defp do_approve_declarations(%{unit: unit, expiration: expiration, limit: limit, user_id: user_id}) do
    Logger.info("approve all declarations with inserted_at + #{expiration} #{unit} < now() limit: #{limit}")

    subquery =
      Declaration
      |> select([d], %{id: d.id})
      |> where([d], d.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^(-1 * expiration), ^unit))
      |> where([d], d.status == ^Declaration.status(:pending))
      |> limit(^limit)

    updates = [status: Declaration.status(:active), updated_by: user_id, updated_at: DateTime.utc_now()]

    query = join(Declaration, :inner, [d], dr in subquery(subquery), dr.id == d.id)

    update_rows(query, updates)
  end

  def do_terminate_declarations(%{limit: limit, user_id: user_id}) do
    subquery =
      Declaration
      |> select([d], %{id: d.id})
      |> where([d], d.end_date < ^NaiveDateTime.utc_now())
      |> where([d], d.status not in ^[Declaration.status(:closed), Declaration.status(:terminated)])
      |> limit(^limit)

    updates = [status: Declaration.status(:closed), updated_by: user_id, updated_at: DateTime.utc_now()]

    query = join(Declaration, :inner, [d], dr in subquery(subquery), dr.id == d.id)

    update_rows(query, updates)
  end

  defp update_rows(query, updates) do
    Repo.transaction(fn ->
      {rows_updated, declarations} =
        Repo.update_all(query, [set: updates], returning: Declarations.updated_fields_list(updates))

      Declarations.log_status_updates(declarations)
      rows_updated
    end)
  end
end
