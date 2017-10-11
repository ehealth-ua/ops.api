defmodule OPS.MedicationRequests do
  @moduledoc false

  alias OPS.MedicationRequest.Schema, as: MedicationRequest
  alias OPS.Repo
  alias OPS.MedicationRequest.Search
  alias OPS.Declarations.Declaration
  alias OPS.MedicationRequest.DoctorSearch
  import Ecto.Changeset
  use OPS.Search

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicationRequest)
  end

  def doctor_list(params) do
    %DoctorSearch{}
    |> changeset(params)
    |> doctor_search()
    |> Repo.paginate(params)
  end

  def update(medication_request, attrs) do
    medication_request
    |> changeset(attrs)
    |> Repo.update_and_log(Map.get(attrs, "updated_by"))
  end

  defp doctor_search(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
    employee_ids =
      changeset
      |> get_change(:employee_id, "")
      |> String.split(",")
      |> Enum.filter(&(&1 != ""))
    filters = changes
      |> Map.delete(:employee_id)
      |> Map.to_list()

    MedicationRequest
    |> join(:left, [mr], d in Declaration,
      d.employee_id == mr.employee_id and
      d.person_id == mr.person_id and
      d.status == ^Declaration.status(:active)
    )
    |> where([mr], ^filters)
    |> filter_by_employees(employee_ids)
  end
  defp doctor_search(changeset), do: {:error, changeset}

  defp filter_by_employees(query, []), do: query
  defp filter_by_employees(query, employee_ids) do
    where(query, [mr], mr.employee_id in ^employee_ids)
  end

  defp changeset(%Search{} = search, attrs) do
    # allow to search by all available fields
    cast(search, attrs, Search.__schema__(:fields))
  end
  defp changeset(%DoctorSearch{} = search, attrs) do
    cast(search, attrs, DoctorSearch.__schema__(:fields))
  end
  defp changeset(%MedicationRequest{} = medication_request, attrs) do
    cast(medication_request, attrs, MedicationRequest.__schema__(:fields))
  end
end
