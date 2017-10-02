defmodule OPS.MockServer do
  @moduledoc false
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json],
    pass:  ["application/json"],
    json_decoder: Poison
  plug :dispatch

  # Il

  get "/api/global_parameters" do
    Plug.Conn.send_resp(conn, 200, parameters() |> wrap_response() |> Poison.encode!())
  end

  def wrap_response(data, code \\ 200) do
    %{
      "meta" => %{
      "code" => code,
      "type" => "list"
    },
      "data" => data
    }
  end

  defp parameters do
    %{
      "verification_request_term_unit" => "DAYS",
      "verification_request_expiration"=> 3
    }
  end
end
