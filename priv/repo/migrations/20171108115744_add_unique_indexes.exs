defmodule OPS.Repo.Migrations.AddUniqueIndexes do
  use Ecto.Migration

  def change do
    create unique_index(:declarations, [:person_id], where: "status = 'active'")
    create unique_index(:declarations, [:declaration_request_id])
    create unique_index(:medication_dispenses, [:medication_request_id], where: "status = 'PROCESSED'")
    create unique_index(:medication_requests, [:request_number])
    create unique_index(:medication_requests, [:medication_request_requests_id])
  end
end
