defmodule OPS.Declarations.Declaration do
  @moduledoc false
  use Ecto.Schema

  @status_active "active"
  @status_closed "closed"
  @status_terminated "terminated"
  @status_rejected "rejected"
  @status_pending "pending_verification"

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "declarations" do
    field :employee_id, Ecto.UUID
    field :person_id, Ecto.UUID
    field :start_date, :date
    field :end_date, :date
    field :status, :string
    field :signed_at, :utc_datetime
    field :created_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :is_active, :boolean, default: false
    field :scope, :string
    field :division_id, Ecto.UUID
    field :legal_entity_id, Ecto.UUID
    field :declaration_request_id, Ecto.UUID
    field :seed, :string

    timestamps(type: :utc_datetime)
  end

  def status(:active), do: @status_active
  def status(:closed), do: @status_closed
  def status(:terminated), do: @status_terminated
  def status(:rejected), do: @status_rejected
  def status(:pending), do: @status_pending
end
