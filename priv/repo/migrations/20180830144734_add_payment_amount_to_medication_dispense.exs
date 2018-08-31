defmodule OPS.Repo.Migrations.AddPaymentAmountToMedicationDispense do
  use Ecto.Migration

  def change do
    alter table(:medication_dispenses) do
      add(:payment_amount, :float)
    end
  end
end
