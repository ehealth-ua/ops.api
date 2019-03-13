defmodule Core.Declarations.Declaration do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @status_active "active"
  @status_closed "closed"
  @status_terminated "terminated"
  @status_rejected "rejected"
  @status_pending "pending_verification"

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "declarations" do
    field(:employee_id, UUID)
    field(:person_id, UUID)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:status, :string)
    field(:signed_at, :utc_datetime_usec)
    field(:created_by, UUID)
    field(:updated_by, UUID)
    field(:is_active, :boolean, default: false)
    field(:scope, :string)
    field(:division_id, UUID)
    field(:legal_entity_id, UUID)
    field(:declaration_request_id, UUID)
    field(:seed, :string)
    field(:reason, :string)
    field(:reason_description, :string)
    field(:overlimit, :boolean, default: false)
    field(:declaration_number, :string)

    timestamps(type: :utc_datetime_usec)
  end

  def status(:active), do: @status_active
  def status(:closed), do: @status_closed
  def status(:terminated), do: @status_terminated
  def status(:rejected), do: @status_rejected
  def status(:pending), do: @status_pending
end
