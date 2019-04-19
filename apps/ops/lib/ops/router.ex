defmodule OPS.Web.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use OPS.Web, :router
  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:put_secure_browser_headers)
  end

  scope "/", OPS.Web do
    pipe_through(:api)

    # query string is too long for this endpoint, so it is POST instead of GET
    post("/declarations/person_ids", DeclarationController, :person_ids)

    resources("/declarations", DeclarationController)
    post("/declarations/with_termination", DeclarationController, :create_with_termination_logic)
    patch("/employees/:employee_id/declarations/actions/terminate", DeclarationController, :terminate_declarations)
    patch("/persons/:person_id/declarations/actions/terminate", DeclarationController, :terminate_declarations)
    patch("/declarations/:id/actions/terminate", DeclarationController, :terminate_declaration)
    post("/declarations_count", DeclarationController, :declarations_count)

    get("/medication_dispenses", MedicationDispenseController, :index)
    post("/medication_dispenses", MedicationDispenseController, :create)
    put("/medication_dispenses/:id", MedicationDispenseController, :update)
    patch("/medication_dispenses/:id/process", MedicationDispenseController, :process)

    resources("/medication_requests", MedicationRequestController, only: [:index, :update, :create])
    post("/doctor_medication_requests", MedicationRequestController, :doctor_list)
    get("/qualify_medication_requests", MedicationRequestController, :qualify_list)
    get("/prequalify_medication_requests", MedicationRequestController, :prequalify_list)
    get("/latest_block", BlockController, :latest_block)
  end
end
