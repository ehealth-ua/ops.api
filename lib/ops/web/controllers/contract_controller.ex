defmodule OPS.Web.ContractController do
  @moduledoc false

  use OPS.Web, :controller

  alias OPS.Contracts

  action_fallback(OPS.Web.FallbackController)

  def show(conn, %{"id" => id}) do
    with {:ok, contract} <- Contracts.get_by_id(id) do
      render(conn, "show.json", contract: contract)
    end
  end
end
