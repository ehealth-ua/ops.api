defmodule OPS.Web.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use OPS.Web, :router
  use Plug.ErrorHandler

  alias Plug.LoggerJSON

  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:put_secure_browser_headers)

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  scope "/", OPS.Web do
    pipe_through(:api)

    resources("/declarations", DeclarationController)
    post("/declarations/with_termination", DeclarationController, :create_with_termination_logic)
    patch("/employees/:id/declarations/actions/terminate", DeclarationController, :terminate_declarations)
    patch("/persons/:id/declarations/actions/terminate", DeclarationController, :terminate_person_declarations)

    get("/medication_dispenses", MedicationDispenseController, :index)
    post("/medication_dispenses", MedicationDispenseController, :create)
    put("/medication_dispenses/:id", MedicationDispenseController, :update)

    resources("/medication_requests", MedicationRequestController, only: [:index, :update, :create])
    post("/doctor_medication_requests", MedicationRequestController, :doctor_list)
    get("/qualify_medication_requests", MedicationRequestController, :qualify_list)
    get("/prequalify_medication_requests", MedicationRequestController, :prequalify_list)
    get("/latest_block", BlockController, :latest_block)
  end

  defp handle_errors(%Plug.Conn{status: 500} = conn, %{kind: kind, reason: reason, stack: stacktrace}) do
    LoggerJSON.log_error(kind, reason, stacktrace)
    send_resp(conn, 500, Poison.encode!(%{errors: %{detail: "Internal server error"}}))
  end

  defp handle_errors(_, _), do: nil
end
