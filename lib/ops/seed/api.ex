defmodule OPS.Seed.API do
  @moduledoc false

  import Ecto.Query

  alias OPS.Repo
  alias OPS.SeedRepo
  alias OPS.Seed.Schema, as: Seed

  @calculate_seed_query "
    WITH concat AS (
      SELECT
        ARRAY_TO_STRING(ARRAY_AGG(
          CONCAT(
            id,
            employee_id,
            start_date,
            end_date,
            signed_at,
            created_by,
            is_active,
            scope,
            division_id,
            legal_entity_id,
            inserted_at,
            declaration_request_id,
            seed
          ) ORDER BY id ASC
        ), '') AS value FROM declarations WHERE DATE(inserted_at) = $1
    )
    SELECT digest(value, 'sha512') as value FROM concat;
  "

  def get_latest() do
    seed_query = from s in Seed,
      order_by: [desc: s.inserted_at],
      limit: 1

    SeedRepo.one(seed_query)
  end

  def get_or_create_seed(date \\ Date.utc_today()) do
    SeedRepo.transaction fn ->
      get_seed(date) || create_seed(date)
    end
  end

  def get_seed(date) do
    seed_query = from s in Seed,
      where: fragment("date(?) = ?", s.inserted_at, ^date)

    SeedRepo.one(seed_query)
  end

  def create_seed(date) do
    payload = %Seed{
      hash: calculated_hash(date)
    }

    SeedRepo.insert(payload)
  end

  def calculated_hash(date) do
    {:ok, %{rows: [[hash_value]], num_rows: 1}} = Repo.query(@calculate_seed_query, [date])

    hash_value
  end
end
