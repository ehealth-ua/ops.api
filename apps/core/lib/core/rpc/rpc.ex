defmodule Core.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  import Ecto.Query

  alias Core.Declarations.Declaration
  alias Core.MedicationRequest.Search
  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias EView.Views.ValidationError

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @last_medication_request_dates_search_params ~w(
    person_id
    medication_id
    medical_program_id
    status
  )

  @type error :: %{
          entry: binary(),
          entry_type: binary(),
          rules: list(map())
        }

  @type errors :: list(error)

  @type validation_changeset_error() :: %{
          type: :validation_failed,
          invalid: errors,
          message: binary()
        }

  @doc """
  Searches medication request by given parameters (string key map) with maximum ended_at field.

  Available parameters (all of them are required):

  | Parameter           | Type                         | Example                                | Description                     |
  | :-----------------: | :--------------------------: | :------------------------------------: | :-----------------------------: |
  | person_id           | `UUID`                       | `72b38c55-4fc9-4ab3-b656-1091af4c557c` |                                 |
  | medication_id       | `UUID`                       | `64841249-7e59-4dfd-93ae-9a48b0f70595` |                                 |
  | medical_program_id  | `UUID`                       | `c4b3bf60-8352-4454-a762-fc67847e3797` |                                 |
  | status              | `binary` or list of `binary` | `ACTIVE` or [`ACTIVE`, `COMPLETED`]    |                                 |

  Returns
    `{:ok, %{"started_at" => Date.t(), "ended_at" => Date.t()}` when medication request is found.
    `{:ok, nil}` when medication request is not found.
    `{:error, Ecto.Changeset.t()}` when search params are invalid.

  ## Examples
      iex> Core.Rpc.last_medication_request_dates(%{
         "person_id" => "4671ab27-57f8-4c55-a618-a042a68c7add",
         "medication_id" => "43ec9534-2250-42bb-94ec-e0a7ad33afd3",
         "medical_program_id" => nil,
         "status" => "ACTIVE"
         })

      {:ok, %{"ended_at" => ~D[2018-12-17], "started_at" => ~D[2018-12-17]}}
  """

  @spec last_medication_request_dates(map()) :: {:error, validation_changeset_error()} | {:ok, map()} | {:ok, nil}
  def last_medication_request_dates(params) do
    %Search{}
    |> MedicationRequests.changeset(Map.take(params, @last_medication_request_dates_search_params))
    |> search_last_medication_request_dates()
  end

  defp search_last_medication_request_dates(%Ecto.Changeset{valid?: true, changes: changes}) do
    statuses = changes |> Map.get(:status, "") |> String.split(",")
    params = changes |> Map.delete(:status) |> Map.to_list()

    result =
      MedicationRequest
      |> select([mr], %{"started_at" => mr.started_at, "ended_at" => mr.ended_at})
      |> where([mr], ^params)
      |> order_by([mr], desc: :ended_at)
      |> add_query_statuses(statuses)
      |> limit([mr], 1)
      |> @read_repo.all()

    if Enum.empty?(result), do: {:ok, nil}, else: {:ok, hd(result)}
  end

  defp search_last_medication_request_dates(%Ecto.Changeset{valid?: false} = changeset) do
    {:error, ValidationError.render("422.query.json", changeset)}
  end

  defp add_query_statuses(query, [""]), do: query
  defp add_query_statuses(query, [status]), do: where(query, [mr], mr.status == ^status)
  defp add_query_statuses(query, statuses), do: where(query, [mr], mr.status in ^statuses)

  @doc """
  Get declarations by list of employee ids

  ## Examples
      iex> Core.Rpc.declarations_by_employees(["4671ab27-57f8-4c55-a618-a042a68c7add"], [:legal_entity_id])
      {:ok, [%{legal_entity_id: "43ec9534-2250-42bb-94ec-e0a7ad33afd3"}]}
  """
  @spec declarations_by_employees(employee_ids :: list(), fields :: list(atom)) :: list
  def declarations_by_employees(employee_ids, [_ | _] = fields) when is_list(employee_ids) do
    {:ok,
     Declaration
     |> select([d], map(d, ^fields))
     |> where([d], d.employee_id in ^employee_ids)
     |> @read_repo.all()}
  end

  @doc """
  Get declaration by params

  ## Examples
      iex> Core.Rpc.get_declaration_by(id: "0042500e-6ac0-45fb-b82a-25f7857c49a8")
      %Core.Declarations.Declaration{}
  """
  @spec get_declaration_by(list) :: %Core.Declarations.Declaration{} | nil
  def get_declaration_by(params) when is_list(params) do
    @read_repo.get_by(Declaration, params)
  end

  @doc """
  Get declarations from filter

  ## Examples
      iex> Core.Rpc.search_declarations([{:person_id, :in, ["0042500e-6ac0-45fb-b82a-25f7857c49a8"]}], [start_date: :asc], {0, 10})
      {:ok, [%Core.Declarations.Declaration{}]}
  """
  @spec search_declarations(list, list, {integer, integer}) :: list(Core.Declarations.Declaration)
  def search_declarations(filter, order_by, {offset, limit}) when is_list(filter) and is_list(order_by) do
    # TODO: apply filtering library

    declarations =
      Declaration
      |> limit(^limit)
      |> offset(^offset)
      |> order_by(^order_by)
      |> @read_repo.all()

    {:ok, declarations}
  end
end
