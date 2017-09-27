defmodule OPS.Web.BlockView do
  @moduledoc false

  use OPS.Web, :view

  alias OPS.Web.BlockView

  def render("show.json", %{block: block}) do
    render_one(block, BlockView, "block.json")
  end

  def render("block.json", %{block: block}) do
    %{
      block_start: block.block_start,
      block_end: block.block_end,
      hash: block.hash,
      inserted_at: block.inserted_at
    }
  end
end
