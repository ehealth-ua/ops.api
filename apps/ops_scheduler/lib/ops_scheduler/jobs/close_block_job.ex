defmodule OpsScheduler.Jobs.CloseBlockJob do
  @moduledoc false

  alias Core.Block.API

  def run do
    API.close_block()
  end
end
