defmodule OPS.API.IL do
  @moduledoc """
  IL API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ops
  use OPS.API.HeadersProcessor

  alias OPS.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def get_global_parameters do
    "/api/global_parameters"
    |> get!()
    |> ResponseDecoder.check_response()
  end

  def send_notification(verification_result) do
    "/internal/hash_chain/verification_failed"
    |> post!(Poison.encode!(%{"data" => verification_result}))
    |> ResponseDecoder.check_response()
  end
end
