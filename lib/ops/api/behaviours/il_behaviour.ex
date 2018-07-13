defmodule OPS.API.IlBehaviour do
  @moduledoc false

  @callback get_global_parameters() ::
              {:ok, result :: map}
              | {:error, reason :: term}
end
