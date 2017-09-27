defmodule OPS.Web.BlockController do
  @moduledoc false

  use OPS.Web, :controller

  alias OPS.Block.API, as: BlockAPI

  action_fallback OPS.Web.FallbackController

  def latest_block(conn, _) do
    block = BlockAPI.get_latest()
    render(conn, "show.json", %{block: block})
  end
end
