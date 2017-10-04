defmodule OPS.BlockRepo.Migrations.VerificationFailures do
  use Ecto.Migration

  def change do
    create table(:verification_failures) do
      add :block_id, references(:blocks), null: true
      add :resolved, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
