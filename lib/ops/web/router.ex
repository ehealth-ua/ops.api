defmodule OPS.Web.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use OPS.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers

    # Uncomment to enable versioning of your API
    # plug Multiverse, gates: [
    #   "2016-07-31": OPS.Web.InitialGate
    # ]

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  scope "/", OPS.Web do
    pipe_through :api

    resources "/declarations", DeclarationController
    get "/reports/declarations", DeclarationReportController, :declarations
    post "/declarations/with_termination", DeclarationController, :create_with_termination_logic
    patch "/employees/:id/declarations/actions/terminate", DeclarationController, :terminate_declarations
    patch "/persons/:id/declarations/actions/terminate", DeclarationController, :terminate_person_declarations

    get "/medication_dispenses", MedicationDispenseController, :index
    post "/medication_dispenses", MedicationDispenseController, :create
    put "/medication_dispenses/:id", MedicationDispenseController, :update
  end
end
