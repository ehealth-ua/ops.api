defmodule OPS.Web.MedicationDispenseView do
  @moduledoc false

  use OPS.Web, :view

  def render("index.json", %{medication_dispenses: medication_dispenses}) do
    render_many(medication_dispenses, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_dispense: medication_dispense}) do
    medication_request = render_one(
      Map.get(medication_dispense, :medication_request),
      OPS.Web.MedicationRequestView,
      "show.json"
    )

    medication_dispense
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.put(:medication_request, medication_request)
  end
end
