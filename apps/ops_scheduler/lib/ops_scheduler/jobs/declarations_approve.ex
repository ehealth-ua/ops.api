defmodule OpsScheduler.Jobs.DeclarationsApprove do
  @moduledoc false

  use Confex, otp_app: :ops_scheduler
  alias Core.Declarations
  alias Core.Declarations.Declaration
  import Ecto.Query
  require Logger

  @il_api Application.get_env(:core, :api_resolvers)[:il]

  def run do
    user_id = Confex.fetch_env!(:core, :system_user)
    limit = config()[:approve_batch_size]

    with {:ok, response} <- @il_api.get_global_parameters(),
         _ <- Logger.info("Global parameters: #{Jason.encode!(response)}"),
         parameters <- Map.fetch!(response, "data"),
         unit <- Map.fetch!(parameters, "verification_request_term_unit"),
         expiration <- parameters |> Map.fetch!("verification_request_expiration") |> String.to_integer() do
      unit =
        unit
        |> String.downcase()
        |> String.replace_trailing("s", "")

      approve_declarations(expiration, unit, limit, user_id)
    else
      error -> Logger.error("Can't start declaration scheduler! #{inspect(error)}")
    end
  end

  defp approve_declarations(expiration, unit, limit, user_id) do
    Logger.info("approve all declarations with inserted_at + #{expiration} #{unit} < now() limit: #{limit}")

    subquery =
      Declaration
      |> select([d], %{id: d.id})
      |> where([d], d.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^(-1 * expiration), ^unit))
      |> where([d], d.status == ^Declaration.status(:pending))
      |> where([d], d.reason == "offline")
      |> limit(^limit)

    updates = [status: Declaration.status(:active), updated_by: user_id, updated_at: DateTime.utc_now()]
    query = join(Declaration, :inner, [d], dr in subquery(subquery), on: dr.id == d.id)

    case Declarations.update_rows(query, updates) do
      {:ok, rows_updated} when rows_updated >= limit ->
        approve_declarations(expiration, unit, limit, user_id)

      _ ->
        :ok
    end
  end
end
