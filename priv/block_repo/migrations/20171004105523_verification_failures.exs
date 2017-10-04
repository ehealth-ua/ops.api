defmodule OPS.BlockRepo.Migrations.VerificationFailures do
  use Ecto.Migration

  def change do
    create table(:verification_failures, primary_key: false) do
      add :block_id, references(:blocks), null: true
      add :resolved, :boolean, default: false, null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end
  end
end
