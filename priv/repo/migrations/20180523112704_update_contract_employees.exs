defmodule OPS.Repo.Migrations.UpdateContractEmployees do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_employees) do
      add(:start_date, :date, null: false)
      add(:end_date, :date)
    end
  end
end
