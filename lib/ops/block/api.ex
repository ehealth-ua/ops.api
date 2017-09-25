defmodule OPS.Block.API do
  @moduledoc false

  import Ecto.Query

  alias OPS.Repo
  alias OPS.BlockRepo
  alias OPS.Block.Schema, as: Block

  @calculate_block_query "
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
    SELECT digest(concat(date($1), value), 'sha512')::text as value FROM concat;
  "

  def get_latest do
    block_query = from s in Block,
      order_by: [desc: s.day],
      limit: 1

    BlockRepo.one(block_query)
  end

  def get_block(date) do
    block_query = from s in Block,
      where: fragment("date(?) = ?", s.day, ^date)

    BlockRepo.one(block_query)
  end

  def close_day(date \\ Timex.shift(Timex.today, days: -1)) do
    payload = %Block{
      hash: calculated_hash(date),
      day: date
    }

    BlockRepo.insert(payload)
  end

  # TODO: handle case when declarations do not exist on a given day
  # TODO: handle case when seed do not exist on a given day
  # TODO: it cannot verify the first day. Related to the fact that there were no declarations on that day. Why?
  def verify_day(date) do
    existing_hash = get_block(date).hash
    do_verify(date, existing_hash)
  end

  def verify_chain do
    query = from s in Block,
      order_by: [asc: s.day],
      offset: 1

    Enum.reduce_while BlockRepo.all(query), :ok, fn block, _acc ->
      existing_hash = block.hash

      case do_verify(block.day, existing_hash) do
        :ok ->
          {:cont, :ok}
        {:error, _} = error ->
          {:halt, error}
      end
    end
  end

  def do_verify(date, existing_hash) do
    reconstructed_hash = calculated_hash(date)

    if reconstructed_hash == existing_hash do
      :ok
    else
      {:error, {date, existing_hash, reconstructed_hash}}
    end
  end

  def calculated_hash(date) do
    {:ok, %{rows: [[hash_value]], num_rows: 1}} = Repo.query(@calculate_block_query, [date])

    hash_value
  end
end
