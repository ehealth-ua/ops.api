defmodule OPS.Repo.Migrations.AddVerificationCodeToMedicationRequests do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      add :verification_code, :string
    end
  end
end
