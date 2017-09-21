defmodule OPS.Web.MedicationDispenseController do
  @moduledoc false

  use OPS.Web, :controller

  alias Scrivener.Page
  alias OPS.MedicationDispenses

  action_fallback OPS.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- MedicationDispenses.list(params) do
      render(conn, "index.json", medication_dispenses: paging.entries, paging: paging)
    end
  end

  def create(conn, %{"medication_dispense" => params}) do
    with {:ok, medication_dispense} <- MedicationDispenses.create(params) do
      conn
      |> put_status(:created)
      |> render("show.json", medication_dispense: medication_dispense)
    end
  end

  def update(conn, %{"id" => id, "medication_dispense" => params}) do
    with %Page{entries: [medication_dispense]} <- MedicationDispenses.list(%{"id" => id}),
         {:ok, medication_dispense} <- MedicationDispenses.update(medication_dispense, params)
    do
      render(conn, "show.json", medication_dispense: medication_dispense)
    end
  end
end
