defmodule OPS.Block.API do
  @moduledoc false

  import Ecto.Query

  alias OPS.Repo
  alias OPS.BlockRepo
  alias OPS.Block.Schema, as: Block

  @query_v1 "
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
            scope,
            division_id,
            legal_entity_id,
            inserted_at,
            declaration_request_id,
            person_id,
            seed
          ) ORDER BY id ASC
        ), '') AS value FROM declarations
        WHERE inserted_at > $1 AND inserted_at <= $2
    )
  SELECT digest(concat(value), 'sha512')::text AS value FROM concat;
  "

  @calculate_block_query %{
    "v1" => @query_v1
  }

  def get_latest do
    block_query = from s in Block,
      order_by: [desc: s.inserted_at],
      limit: 1

    BlockRepo.one(block_query)
  end

  def close_block do
    block_start = get_latest().block_end
    block_end = DateTime.utc_now()

    block = %Block{
      hash: calculated_hash(current_version(), block_start, block_end),
      block_start: block_start,
      block_end: block_end,
      version: to_string(current_version())
    }

    BlockRepo.insert(block)
  end

  def verify_chain do
    query = from s in Block,
      order_by: [asc: s.inserted_at],
      offset: 1

    # TODO: run this in parallel
    # TODO: no need to stop, e.g. {:halt, error}
    # TODO: write to LOG both :success and :error status
    result =
      Enum.reduce BlockRepo.all(query), [], fn block, acc ->
        case do_verify(block) do
          :ok ->
            acc
          error_info ->
            [error_info|acc]
        end
      end

    if Enum.empty? result do
      :ok
    else
      {:error, result}
    end
  end

  def verify_block(time) do
    if block = get_block(time) do
      do_verify(block.hash)
    else
      {:error, "No block covers provided time: #{inspect time}."}
    end
  end

  def get_block(time) do
    block_query = from s in Block,
      where: fragment("? > ? AND ? <= ?", s.block_start, ^time, s.block_end, ^time)

    BlockRepo.one(block_query)
  end

  def do_verify(existing_block) do
    existing_hash = existing_block.hash
    reconstructed_hash = calculated_hash(existing_block.version, existing_block.block_start, existing_block.block_end)

    if reconstructed_hash == existing_hash do
      :ok
    else
      %{block: existing_block, reconstructed_hash: reconstructed_hash}
    end
  end

  def calculated_hash(version, from, to) do
    {:ok, %{rows: [[hash_value]], num_rows: 1}} = Repo.query(@calculate_block_query[version], [from, to])

    hash_value
  end

  # Must be adjusted every time
  # a hash algorithm changes
  def current_version do
    "v1"
  end
end
