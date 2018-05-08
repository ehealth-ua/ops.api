defmodule OPS.Contracts.ContractSearch do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @primary_key false
  embedded_schema do
    field(:id, UUID)
    field(:date_from_start_date, :date)
    field(:date_to_start_date, :date)
    field(:date_from_end_date, :date)
    field(:date_to_end_date, :date)
    field(:status, :string)
    field(:legal_entity_id, UUID)
    field(:contractor_legal_entity_id, UUID)
    field(:contractor_owner_id, UUID)
    field(:nhs_signer_id, UUID)
    field(:contract_number, :string)
    field(:is_suspended, :boolean)
  end
end
