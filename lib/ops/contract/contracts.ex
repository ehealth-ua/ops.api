defmodule OPS.Contracts do
  @moduledoc false

  alias OPS.Contracts.Contract
  alias OPS.Repo

  def get_by_id(id) do
    with contract = %Contract{} <- Repo.get(Contract, id) do
      {:ok, contract}
    end
  end
end
