defmodule Core.API.IlBehaviour do
  @moduledoc false

  @callback get_global_parameters() :: {:ok, result :: map} | {:error, reason :: term}

  @callback send_notification(verification_result :: map) :: {:ok, result :: map} | {:error, reason :: term}
end
