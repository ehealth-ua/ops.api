defmodule OPS.MedicationRequests do
  @moduledoc false

  alias OPS.MedicationRequest.Schema, as: MedicationRequest
  alias OPS.MedicationDispense.Schema, as: MedicationDispense
  alias OPS.Repo
  alias OPS.MedicationRequest.Search
  alias OPS.Declarations.Declaration
  alias OPS.MedicationRequest.DoctorSearch
  alias OPS.MedicationRequest.PersonSearch
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

  def person_list(params) do
    %PersonSearch{}
    |> changeset(params)
    |> person_search()
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

  defp person_search(%Ecto.Changeset{valid?: true, changes: changes}) do
    filters = Map.to_list(changes)
    medication_request_statuses = [
      MedicationRequest.status(:active),
      MedicationRequest.status(:completed)
    ]

    {:ok,
      MedicationRequest
      |> join(:left, [mr], md in MedicationDispense, md.medication_request_id == mr.id)
      |> where([mr, md], ^filters)
      |> where([mr, md], mr.status in ^medication_request_statuses)
      |> where([mr, md], md.status == ^MedicationDispense.status(:processed))
      |> select([mr, md], mr.id)
      |> Repo.all
    }
  end
  defp person_search(changeset), do: {:error, changeset}

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
  defp changeset(%PersonSearch{} = search, attrs) do
    search
    |> cast(attrs, ~w(person_id)a)
    |> validate_required(~w(person_id)a)
  end
end
