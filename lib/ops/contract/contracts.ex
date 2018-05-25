defmodule OPS.Contracts do
  @moduledoc false

  use OPS.Search
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Changeset
  alias OPS.Repo
  alias OPS.Contracts.{Contract, ContractSearch, ContractIDs}
  alias OPS.Contracts.ContractEmployee
  alias OPS.Contracts.ContractDivision

  @fields_required ~w(
    id
    start_date
    end_date
    status
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_rmsp_amount
    nhs_legal_entity_id
    nhs_signer_id
    nhs_payment_method
    nhs_payment_details
    nhs_signer_base
    issue_city
    nhs_contract_price
    contract_number
    contract_request_id
    is_suspended
    is_active
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    status_reason
    external_contractor_flag
    external_contractors
  )a

  @fields_to_drop ~w(
    date_from_start_date
    date_to_start_date
    date_from_end_date
    date_to_end_date
    legal_entity_id
  )a

  @status_verified Contract.status(:verified)
  @status_terminated Contract.status(:terminated)

  def create(%{"contract_number" => contract_number} = params) when not is_nil(contract_number) do
    contract =
      Contract
      |> where([c], c.contract_number == ^contract_number)
      |> Repo.one()

    case contract do
      %Contract{status: @status_verified} ->
        contract = load_references(contract)

        ContractEmployee
        |> where([ce], ce.contract_id == ^contract.id)
        |> Repo.update_all(set: [end_date: Date.utc_today(), updated_by: Map.get(params, "updated_by")])

        Repo.transaction(fn ->
          contract
          |> changeset(%{"status" => @status_terminated})
          |> Repo.update()

          contract_employees =
            contract.contract_employees
            |> Poison.encode!()
            |> Poison.decode!()
            |> Enum.map(&Map.drop(&1, ~w(id contract_id inserted_by updated_by)))

          contract_divisions =
            contract.contract_divisions
            |> Poison.encode!()
            |> Poison.decode!()
            |> Enum.map(&Map.get(&1, "division_id"))

          new_contract_params =
            params
            |> Map.put("contractor_employee_divisions", contract_employees)
            |> Map.put("contract_divisions", contract_divisions)

          with {:ok, new_contract} <- do_create(new_contract_params) do
            new_contract
          end
        end)

      nil ->
        do_create(params)

      _ ->
        {:error, {:"422", "There is no active contract with such contract_number"}}
    end
  end

  @doc "This should never happen"
  def create(_), do: {:error, {:"422", "Contract number is required"}}

  defp do_create(params) do
    with {:ok, contract} <-
           %Contract{}
           |> changeset(params)
           |> Repo.insert() do
      {:ok, load_references(contract)}
    end
  end

  def get_by_id(id) do
    with contract = %Contract{} <- Repo.get(Contract, id) do
      {:ok, load_references(contract)}
    end
  end

  def list_contracts(params) do
    %ContractSearch{}
    |> changeset(params)
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
    |> join(:left, [c], ce in ContractEmployee, c.id == ce.contract_id)
    |> join(:left, [c], cd in ContractDivision, c.id == cd.contract_id)
    |> preload([c, ce, cd], contract_employees: ce, contract_divisions: cd)
  end

  defp changeset(%ContractSearch{} = contract, attrs) do
    fields = ContractSearch.__schema__(:fields)

    cast(contract, attrs, fields)
  end

  defp changeset(%Contract{} = contract, attrs) do
    inserted_by = Map.get(attrs, "inserted_by")
    updated_by = Map.get(attrs, "updated_by")

    attrs =
      case Map.get(attrs, "contractor_employee_divisions") do
        nil ->
          attrs

        contractor_employee_divisions ->
          contractor_employee_divisions =
            Enum.map(
              contractor_employee_divisions,
              &(&1
                |> Map.put("start_date", Map.get(attrs, "start_date"))
                |> Map.put("inserted_by", inserted_by)
                |> Map.put("updated_by", updated_by))
            )

          Map.put(attrs, "contract_employees", contractor_employee_divisions)
      end

    attrs =
      case Map.get(attrs, "contractor_divisions") do
        nil ->
          attrs

        contractor_divisions ->
          contractor_divisions =
            Enum.map(
              contractor_divisions,
              &%{"division_id" => &1, "inserted_by" => inserted_by, "updated_by" => updated_by}
            )

          Map.put(attrs, "contract_divisions", contractor_divisions)
      end

    contract
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> cast_assoc(:contract_employees)
    |> cast_assoc(:contract_divisions)
    |> validate_required(@fields_required)
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

  defp load_references(%Contract{} = contract) do
    contract
    |> Repo.preload(:contract_employees)
    |> Repo.preload(:contract_divisions)
  end
end
