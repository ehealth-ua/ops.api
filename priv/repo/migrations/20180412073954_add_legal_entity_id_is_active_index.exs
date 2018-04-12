defmodule OPS.Repo.Migrations.AddLegalEntityIdIsActiveIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(index(:declarations, [:legal_entity_id, :is_active]))
  end
end
