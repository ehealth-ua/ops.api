defmodule OPS.Web.MedicationRequestView do
  @moduledoc false

  use OPS.Web, :view

  def render("index.json", %{medication_requests: medication_requests}) do
    render_many(medication_requests, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_request: medication_request}) do
    medication_request
  end

  def render("qualify_list.json", %{ids: ids}) do
    ids
  end
end
