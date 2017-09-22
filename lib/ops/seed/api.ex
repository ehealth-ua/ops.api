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
    SELECT digest(concat(date($1), value), 'sha512') as value FROM concat;
  "

  def get_latest() do
    seed_query = from s in Seed,
      order_by: [desc: s.inserted_at],
      limit: 1

    SeedRepo.one(seed_query)
  end

  def get_seed(date) do
    seed_query = from s in Seed,
      where: fragment("date(?) = ?", s.inserted_at, ^date)

    SeedRepo.one(seed_query)
  end

  def close_day(date \\ Timex.shift(Timex.today, days: -1)) do
    payload = %Seed{
      hash: calculated_hash(date)
    }

    SeedRepo.insert(payload)
  end

  def verify_day(date) do
    existing_hash = get_seed(date).hash
    do_compare(date, existing_hash)
  end

  def verify_chain do
    Enum.reduce_while SeedRepo.all(Seed), :ok, fn seed, _acc ->
      existing_hash = seed.hash

      case do_compare(DateTime.to_date(seed.inserted_at), existing_hash) do
        :ok ->
          {:cont, :ok}
        {:error, _} = error ->
          {:halt, error}
      end
    end
  end

  def calculated_hash(date) do
    {:ok, %{rows: [[hash_value]], num_rows: 1}} = Repo.query(@calculate_seed_query, [date])

    hash_value
  end

  def do_compare(date, existing_hash) do
    reconstructed_hash = calculated_hash(date)

    if reconstructed_hash == existing_hash do
      :ok
    else
      {:error, {date, existing_hash, reconstructed_hash}}
    end
  end
end
