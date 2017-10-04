defmodule OPS.Block.API do
  @moduledoc false

  import Ecto.Query

  alias OPS.Repo
  alias OPS.BlockRepo
  alias OPS.Block.Schema, as: Block
  alias OPS.API.IL
  alias OPS.Declarations.Declaration
  alias OPS.VerificationFailure.API, as: VerificationFailureAPI

  def get_latest do
    block_query = from s in Block,
      order_by: [desc: s.inserted_at],
      limit: 1

    BlockRepo.one(block_query)
  end

  def get_verification_candidates do
    first_block = BlockRepo.one(first(Block, :block_start))

    query = from b in Block,
      left_join: vf in assoc(b, :verification_failures),
      where: is_nil(vf.id) or vf.resolved == true,
      where: b.id != ^first_block.id

    BlockRepo.all(query)
  end

  def get_unresolved_mangled_blocks do
    query = from b in Block,
      left_join: vf in assoc(b, :verification_failures),
      where: vf.resolved == false

    BlockRepo.all(query)
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

  def verify_chain_and_notify do
    case verify_chain() do
      {:error, new, previous} ->
        prepare_fun = fn block ->
          %{
            block_id: block.id,
            original_hash: block.hash,
            version: block.version
          }
        end

        IL.send_notification(%{
          newly_mangled_blocks: Enum.map(new, prepare_fun),
          previously_mangled_blocks: Enum.map(previous, prepare_fun)
        })
      _ ->
        :ok
    end
  end

  def verify_chain do
    # TODO: run this in parallel
    # TODO: write to LOG both :success and :error status
    previously_mangled_blocks = get_unresolved_mangled_blocks()

    newly_mangled_blocks =
      Enum.reduce get_verification_candidates(), [], fn block, acc ->
        case do_verify(block) do
          :ok ->
            acc
          error_info ->
            [error_info|acc]
        end
      end

    if Enum.empty?(newly_mangled_blocks) && Enum.empty?(previously_mangled_blocks) do
      :ok
    else
      {:error, newly_mangled_blocks, previously_mangled_blocks}
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

  def do_verify(block) do
    existing_hash = block.hash
    reconstructed_hash = calculated_hash(block.version, block.block_start, block.block_end)
    declaration_hashes_match? = verify_declarations_hashes(block.hash, block.block_end)

    if (reconstructed_hash == existing_hash) && declaration_hashes_match? do
      :ok
    else
      VerificationFailureAPI.mark_as_mangled!(block)

      block
    end
  end

  def calculated_hash(version, from, to) do
    {:ok, %{rows: [[hash_value]], num_rows: 1}} = Repo.query(current_version_query(version), [from, to])

    hash_value
  end

  # declarations from next block will tell if block under verification
  # has been recalculated
  def verify_declarations_hashes(block_hash, block_end) do
    if next_block = BlockRepo.one(from b in Block, where: b.block_start == ^block_end) do
      query1 =
        from d in Declaration,
        where: d.inserted_at > ^next_block.block_start,
        where: d.inserted_at <= ^next_block.block_end,
        where: d.seed == ^block_hash,
        select: count(1)

      query2 =
        from d in Declaration,
        where: d.inserted_at > ^next_block.block_start,
        where: d.inserted_at <= ^next_block.block_end,
        select: count(1)

      Repo.one(query1) == Repo.one(query2)
    else
      true
    end
  end

  def current_version do
    Application.get_env(:ops, :current_block_version)
  end

  def current_version_query(version) do
    Application.get_env(:ops, :block_versions)[version]
  end
end
