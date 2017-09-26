defmodule OPS.Repo.Migrations.FixMedicationRequestSchema do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      remove :dosage_instuction
      remove :note
    end

    rename table(:medication_requests), :recalled_at, to: :rejected_at
    rename table(:medication_requests), :recalled_by, to: :rejected_by
    rename table(:medication_requests), :recall_reason, to: :reject_reason
  end
end
