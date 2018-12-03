defmodule Core.API.IL do
  @moduledoc """
  IL API client
  """

  use Confex, otp_app: :core
  use Core.API.HeadersProcessor
  use HTTPoison.Base

  alias Core.API.ResponseDecoder

  @behaviour Core.API.IlBehaviour

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def get_global_parameters do
    "/api/global_parameters"
    |> get!()
    |> ResponseDecoder.check_response()
  end

  def send_notification(verification_result) do
    "/internal/hash_chain/verification_failed"
    |> post!(Jason.encode!(%{"data" => verification_result}))
    |> ResponseDecoder.check_response()
  end
end
