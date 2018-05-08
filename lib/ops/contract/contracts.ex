defmodule OPS.Contracts do
  @moduledoc false

  use OPS.Search
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  alias OPS.Repo
  alias OPS.Contracts.{Contract, ContractSearch, ContractIDs}

  @fields_to_drop ~w(
    date_from_start_date
    date_to_start_date
    date_from_end_date
    date_to_end_date
    legal_entity_id
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

  def suspend(params) do
    with %Changeset{valid?: true} <- contract_ids_changeset(params) do
      update_is_suspended(params["ids"], true)
    end
  end

  def renew(params) do
    with %Changeset{valid?: true} <- contract_ids_changeset(params) do
      update_is_suspended(params["ids"], false)
    end
  end

  defp update_is_suspended(ids, is_suspended) when is_boolean(is_suspended) do
    ids = String.split(ids, ",")
    query = from(c in Contract, where: c.id in ^ids)

    case Repo.update_all(query, set: [is_suspended: is_suspended]) do
      {suspended, _} -> {:ok, suspended}
      err -> err
    end
  end

  def get_search_query(entity, changes) do
    date_from_start_date = Map.get(changes, :date_from_start_date)
    date_to_start_date = Map.get(changes, :date_to_start_date)
    date_from_end_date = Map.get(changes, :date_from_end_date)
    date_to_end_date = Map.get(changes, :date_to_end_date)
    legal_entity_id = Map.get(changes, :legal_entity_id)

    params = Map.drop(changes, @fields_to_drop)

    entity
    |> super(params)
    |> add_date_range_at_query(:start_date, date_from_start_date, date_to_start_date)
    |> add_date_range_at_query(:end_date, date_from_end_date, date_to_end_date)
    |> add_legal_entity_id_query(legal_entity_id)
  end

  defp contract_changeset(%ContractSearch{} = contract, attrs) do
    fields = ContractSearch.__schema__(:fields)

    cast(contract, attrs, fields)
  end

  defp contract_ids_changeset(attrs) do
    required = ContractIDs.__schema__(:fields)

    %ContractIDs{}
    |> cast(attrs, required)
    |> validate_required(required)
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

  defp add_legal_entity_id_query(query, nil), do: query

  defp add_legal_entity_id_query(query, legal_entity_id) do
    where(query, [c], c.nhs_legal_entity_id == ^legal_entity_id or c.contractor_legal_entity_id == ^legal_entity_id)
  end
end
