defmodule OPS.MedicationRequests do
  @moduledoc false

  alias OPS.MedicationRequest.Schema, as: MedicationRequest
  alias OPS.Repo
  alias OPS.MedicationRequest.Search
  import Ecto.Changeset
  use OPS.Search

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicationRequest)
  end

  defp changeset(%Search{} = search, attrs) do
    # allow to search by all available fields
    cast(search, attrs, Search.__schema__(:fields))
  end
end
