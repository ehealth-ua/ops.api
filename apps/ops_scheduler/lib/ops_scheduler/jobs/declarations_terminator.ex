defmodule OpsScheduler.Jobs.DeclarationsTerminator do
  @moduledoc false

  use Confex, otp_app: :ops_scheduler
  alias Core.Declarations
  alias Core.Declarations.Declaration
  import Ecto.Query
  require Logger

  @il_api Application.get_env(:core, :api_resolvers)[:il]

  def run do
    user_id = Confex.fetch_env!(:core, :system_user)
    limit = config()[:termination_batch_size]

    with {:ok, response} <- @il_api.get_global_parameters(),
         _ <- Logger.info("Global parameters: #{Jason.encode!(response)}"),
         parameters <- Map.fetch!(response, "data"),
         unit <- Map.fetch!(parameters, "verification_request_term_unit"),
         expiration <- parameters |> Map.fetch!("verification_request_expiration") |> String.to_integer() do
      unit =
        unit
        |> String.downcase()
        |> String.replace_trailing("s", "")

      terminate_declarations(expiration, unit, limit, user_id)
    else
      error -> Logger.error("Can't start declaration scheduler! #{inspect(error)}")
    end
  end

  defp terminate_declarations(expiration, unit, limit, user_id) do
    Logger.info("terminate all declarations with inserted_at + #{expiration} #{unit} < now() limit: #{limit}")

    subquery =
      Declaration
      |> select([d], %{id: d.id})
      |> where([d], d.end_date < ^NaiveDateTime.utc_now())
      |> where([d], d.status not in ^[Declaration.status(:closed), Declaration.status(:terminated)])
      |> limit(^limit)

    updates = [status: Declaration.status(:closed), updated_by: user_id, updated_at: DateTime.utc_now()]
    query = join(Declaration, :inner, [d], dr in subquery(subquery), on: dr.id == d.id)

    case Declarations.update_rows(query, updates) do
      {:ok, rows_updated} when rows_updated >= limit ->
        terminate_declarations(expiration, unit, limit, user_id)

      _ ->
        :ok
    end
  end
end
