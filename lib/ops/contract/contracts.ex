defmodule OPS.Contracts do
  @moduledoc false

  use OPS.Search
  import Ecto.{Query, Changeset}, warn: false
  alias OPS.Contracts.Contract
  alias OPS.Contracts.ContractSearch
  alias OPS.Repo

  @date_fields ~w(
    date_from_start_date
    date_to_start_date
    date_from_end_date
    date_to_end_date
    )a

  def get_by_id(id) do
    with contract = %Contract{} <- Repo.get(Contract, id) do
      {:ok, contract}
    end
  end

  def list_contracts(params) do
    %ContractSearch{}
    |> contract_changeset(params)
    |> search(params, Contract)
  end

  defp contract_changeset(%ContractSearch{} = contract, attrs) do
    fields = ContractSearch.__schema__(:fields)

    cast(contract, attrs, fields)
  end

  def get_search_query(entity, changes) do
    date_from_start_date = Map.get(changes, :date_from_start_date)
    date_to_start_date = Map.get(changes, :date_to_start_date)
    date_from_end_date = Map.get(changes, :date_from_end_date)
    date_to_end_date = Map.get(changes, :date_to_end_date)

    params = Map.drop(changes, @date_fields)

    entity
    |> super(params)
    |> add_date_range_at_query(:start_date, date_from_start_date, date_to_start_date)
    |> add_date_range_at_query(:end_date, date_from_end_date, date_to_end_date)
  end

  defp add_date_range_at_query(query, _, nil, nil), do: query

  defp add_date_range_at_query(query, attr, date_from, nil) do
    where(query, [c], field(c, ^attr) >= ^date_from)
  end

  defp add_date_range_at_query(query, attr, nil, date_to) do
    where(query, [c], field(c, ^attr) <= ^date_to)
  end

  defp add_date_range_at_query(query, attr, date_from, date_to) do
    where(query, [c], fragment("? BETWEEN ? AND ?", field(c, ^attr), ^date_from, ^date_to))
  end
end
