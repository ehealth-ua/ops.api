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
    Map.take(contract, ~w(
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
  end

  def render("suspended.json", %{suspended: suspended}), do: %{suspended: suspended}
  def render("renewed.json", %{renewed: renewed}), do: %{renewed: renewed}
end
