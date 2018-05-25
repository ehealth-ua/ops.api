defmodule OPS.Web.ContractController do
  @moduledoc false

  use OPS.Web, :controller

  alias OPS.Contracts
  alias Scrivener.Page

  action_fallback(OPS.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- Contracts.list_contracts(params) do
      render(conn, "index.json", contracts: paging.entries, paging: paging)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, contract} <- Contracts.get_by_id(id) do
      render(conn, "show.json", contract: contract)
    end
  end

  def create(conn, params) do
    with {:ok, contract} <- Contracts.create(params) do
      render(conn, "show.json", contract: contract)
    end
  end

  def suspend(conn, params) do
    with {:ok, suspended} <- Contracts.suspend(params) do
      render(conn, "suspended.json", suspended: suspended)
    end
  end

  def renew(conn, params) do
    with {:ok, renewed} <- Contracts.renew(params) do
      render(conn, "renewed.json", renewed: renewed)
    end
  end
end
