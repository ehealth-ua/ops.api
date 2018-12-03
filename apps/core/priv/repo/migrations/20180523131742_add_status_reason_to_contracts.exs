defmodule Core.Repo.Migrations.AddStatusReasonToContracts do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add(:status_reason, :string)
    end
  end
end
