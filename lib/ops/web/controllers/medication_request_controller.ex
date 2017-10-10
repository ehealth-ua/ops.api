defmodule OPS.Web.MedicationRequestController do
  @moduledoc false

  use OPS.Web, :controller

  alias Scrivener.Page
  alias OPS.MedicationRequests

  action_fallback OPS.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- MedicationRequests.list(params) do
      render(conn, "index.json", medication_requests: paging.entries, paging: paging)
    end
  end

  def doctor_list(conn, params) do
    with %Page{} = paging <- MedicationRequests.doctor_list(params) do
      render(conn, "index.json", medication_requests: paging.entries, paging: paging)
    end
  end
end
