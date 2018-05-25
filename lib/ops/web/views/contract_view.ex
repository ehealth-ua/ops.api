defmodule OPS.Web.ContractView do
  @moduledoc false

  use OPS.Web, :view

  def render("index.json", %{contracts: contracts}) do
    render_many(contracts, __MODULE__, "contract.json")
  end

  def render("show.json", %{contract: contract}) do
    render_one(contract, __MODULE__, "contract.json")
  end

  def render("contract.json", %{contract: contract}) do
    contract
    |> Map.take(~w(
      id
      start_date
      end_date
      status
      contractor_legal_entity_id
      contractor_owner_id
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      external_contractors
      nhs_legal_entity_id
      nhs_signer_id
      nhs_payment_method
      nhs_signer_base
      nhs_payment_details
      issue_city
      nhs_contract_price
      contract_number
      is_suspended
      contract_request_id
    )a)
    |> Map.put(
      "contract_employees",
      Enum.map(
        contract.contract_employees,
        &render_one(&1, __MODULE__, "contract_employee.json", as: :contract_employee)
      )
    )
    |> Map.put(
      "contract_divisions",
      Enum.map(
        contract.contract_divisions,
        &render_one(&1, __MODULE__, "contract_division.json", as: :contract_division)
      )
    )
  end

  def render("suspended.json", %{suspended: suspended}), do: %{suspended: suspended}
  def render("renewed.json", %{renewed: renewed}), do: %{renewed: renewed}

  def render("contract_employee.json", %{contract_employee: contract_employee}) do
    Map.take(contract_employee, ~w(
      employee_id
      division_id
      staff_units
      declaration_limit
      start_date
      end_date
      inserted_by
      updated_by
    )a)
  end

  def render("contract_division.json", %{contract_division: contract_division}), do: contract_division.division_id
end
