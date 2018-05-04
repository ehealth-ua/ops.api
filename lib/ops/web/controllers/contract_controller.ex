defmodule OPS.Web.ContractController do
  @moduledoc false

  use OPS.Web, :controller

  alias OPS.Contracts
  alias Scrivener.Page

  action_fallback(OPS.Web.FallbackController)

  def show(conn, %{"id" => id}) do
    with {:ok, contract} <- Contracts.get_by_id(id) do
      render(conn, "show.json", contract: contract)
    end
  end

  def index(conn, params) do
    with %Page{} = paging <- Contracts.list_contracts(params) do
      render(conn, "index.json", contracts: paging.entries, paging: paging)
    end
  end
end
