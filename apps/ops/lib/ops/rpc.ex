defmodule OPS.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  import Ecto.Query

  alias Core.Declarations
  alias Core.Declarations.Declaration
  alias Core.MedicationRequest.Search
  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.Changeset
  alias EView.Views.ValidationError
  alias OPS.Web.DeclarationView

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @last_medication_request_dates_search_params ~w(
    person_id
    medication_id
    medical_program_id
    status
  )

  @type declaration :: %{
          id: Ecto.UUID.type(),
          employee_id: Ecto.UUID.type(),
          person_id: Ecto.UUID.type(),
          start_date: Date.t(),
          end_date: Date.t(),
          status: binary(),
          signed_at: DateTime.t(),
          created_by: Ecto.UUID.type(),
          updated_by: Ecto.UUID.type(),
          is_active: boolean(),
          scope: binary(),
          division_id: Ecto.UUID.type(),
          legal_entity_id: Ecto.UUID.type(),
          declaration_request_id: Ecto.UUID.type(),
          reason: binary(),
          reason_description: binary(),
          declaration_number: binary(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

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
      iex> OPS.Rpc.last_medication_request_dates(%{
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
      iex> OPS.Rpc.declarations_by_employees(["4671ab27-57f8-4c55-a618-a042a68c7add"], [:legal_entity_id])
      [%{legal_entity_id: "43ec9534-2250-42bb-94ec-e0a7ad33afd3"}]
  """
  @spec declarations_by_employees(employee_ids :: list(), fields :: list(atom)) :: list
  def declarations_by_employees(employee_ids, [_ | _] = fields) when is_list(employee_ids) do
    Declaration
    |> select([d], map(d, ^fields))
    |> where([d], d.employee_id in ^employee_ids)
    |> @read_repo.all()
  end

  @doc """
  Get declaration by params

  ## Examples
      iex> OPS.Rpc.get_declaration(id: "0042500e-6ac0-45fb-b82a-25f7857c49a8")
      %{
        id: "cdb4a85b-f12c-46c6-b840-590467e26acf",
        created_by: "738c8cc1-ae9b-42a5-8660-4b7612b2b35c",
        declaration_number: "0",
        declaration_request_id: "382cc67b-7ade-4905-b8a9-0dfe2e9b9da0",
        division_id: "bb15bdde-ffd2-4683-8ca9-03c86b1e6846",
        employee_id: "f8cc0822-f214-4eea-a7d4-d03142901eb1",
        end_date: ~D[2019-01-21],
        inserted_at: #DateTime<2019-01-30 12:24:36.455175Z>,
        is_active: true,
        legal_entity_id: "980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2",
        person_id: "071a2783-f752-42d9-bcfc-44ddc7eb923d",
        reason: nil,
        reason_description: nil,
        scope: "",
        signed_at: #DateTime<2019-01-20 12:24:36.442837Z>,
        start_date: ~D[2019-01-20],
        status: "active",
        updated_at: #DateTime<2019-01-30 12:24:36.455185Z>,
        updated_by: "8dac0fc6-04fd-4e62-9711-a85c0a42992d"
      }
  """
  @spec get_declaration(list) :: {:ok, declaration} | nil
  def get_declaration(params) when is_list(params) do
    with %{} = declaration <- @read_repo.get_by(Declaration, params) do
      {:ok, DeclarationView.render("show.json", %{declaration: declaration})}
    end
  end

  @doc """
  Get declarations by filter
  Check avaiable formats for filter here https://github.com/edenlabllc/ecto_filter

  Available parameters:

  | Parameter           | Type                          | Example                                   | Description                     |
  | :-----------------: | :---------------------------: | :---------------------------------------: | :-----------------------------: |
  | filter              | `list`                        | `[{:reason, :equal, "no_tax_id"}]`        | Required. Uses filtering format |
  | order_by            | `list`                        | `[asc: :inserted_at]` or `[desc: :status]`|                                 |
  | cursor              | `{integer, integer}` or `nil` | `{0, 10}`                                 |                                 |

  ## Examples
      iex> OPS.Rpc.search_declarations([{:person_id, :in, ["0042500e-6ac0-45fb-b82a-25f7857c49a8"]}], [start_date: :asc], {0, 10})
      {:ok, [
        %{
          id: "cdb4a85b-f12c-46c6-b840-590467e26acf",
          created_by: "738c8cc1-ae9b-42a5-8660-4b7612b2b35c",
          declaration_number: "0",
          declaration_request_id: "382cc67b-7ade-4905-b8a9-0dfe2e9b9da0",
          division_id: "bb15bdde-ffd2-4683-8ca9-03c86b1e6846",
          employee_id: "f8cc0822-f214-4eea-a7d4-d03142901eb1",
          end_date: ~D[2019-01-21],
          inserted_at: #DateTime<2019-01-30 12:24:36.455175Z>,
          is_active: true,
          legal_entity_id: "980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2",
          person_id: "071a2783-f752-42d9-bcfc-44ddc7eb923d",
          reason: nil,
          reason_description: nil,
          scope: "",
          signed_at: #DateTime<2019-01-20 12:24:36.442837Z>,
          start_date: ~D[2019-01-20],
          status: "active",
          updated_at: #DateTime<2019-01-30 12:24:36.455185Z>,
          updated_by: "8dac0fc6-04fd-4e62-9711-a85c0a42992d"
        }
      ]}
  """
  @spec search_declarations(list, list, nil | {integer, integer}) :: {:ok, list(declaration)}
  def search_declarations([_ | _] = filter, order_by \\ [], cursor \\ nil) when filter != [] and is_list(order_by) do
    declarations =
      Declaration
      |> EctoFilter.filter(filter)
      |> apply_cursor(cursor)
      |> order_by(^order_by)
      |> @read_repo.all()

    {:ok, DeclarationView.render("index.json", %{declarations: declarations})}
  end

  defp apply_cursor(query, {offset, limit}), do: query |> limit(^limit) |> offset(^offset)
  defp apply_cursor(query, _), do: query

  @doc """
  Update declaration

  Available parameters:

  | Parameter              | Type                         | Example                                | Description                     |
  | :--------------------: | :--------------------------: | :------------------------------------: | :-----------------------------: |
  | updated_by             | `UUID`                       | `72b38c55-4fc9-4ab3-b656-1091af4c557c` | Required                        |
  | employee_id            | `UUID`                       | `dfe13714-92ed-448b-90d2-cccb8640948a` |                                 |
  | person_id              | `UUID`                       | `fba89efe-0cad-4c11-ad1f-d0cdce26b03a` |                                 |
  | start_date             | `Date` or `binary`           | `~D[2015-10-10]` or `2015-10-10`       |                                 |
  | end_date               | `Date` or `binary`           | `~D[2030-10-10]` or `2030-10-10`       |                                 |
  | signed_at              | `DateTime` or `binary`       | `2019-01-30 12:20:51`                  |                                 |
  | status                 | `binary`                     | `active`                               |                                 |
  | created_by             | `UUID`                       | `99a604f9-c319-4d93-a802-a5798d8efdf7` |                                 |
  | updated_by             | `UUID`                       | `99a604f9-c319-4d93-a802-a5798d8efdf7` |                                 |
  | is_active              | `boolean`                    | `true`                                 |                                 |
  | scope                  | `binary`                     | `family_doctor`                        |                                 |
  | division_id            | `UUID`                       | `e217193a-e46b-49d9-9a66-79926abfefe8` |                                 |
  | legal_entity_id        | `UUID`                       | `b5b30e2c-e347-49ba-a4e4-a52eaa057463` |                                 |
  | declaration_request_id | `UUID`                       | `cc3efcde-16b0-45a4-b0b8-f278d7b3c9ca` |                                 |

  ## Examples
      iex> OPS.Rpc.update_declaration("0042500e-6ac0-45fb-b82a-25f7857c49a8", %{"status" => "active"})
      {:ok,
        %{
          id: "cdb4a85b-f12c-46c6-b840-590467e26acf",
          created_by: "738c8cc1-ae9b-42a5-8660-4b7612b2b35c",
          declaration_number: "0",
          declaration_request_id: "382cc67b-7ade-4905-b8a9-0dfe2e9b9da0",
          division_id: "bb15bdde-ffd2-4683-8ca9-03c86b1e6846",
          employee_id: "f8cc0822-f214-4eea-a7d4-d03142901eb1",
          end_date: ~D[2019-01-21],
          inserted_at: #DateTime<2019-01-30 12:24:36.455175Z>,
          is_active: true,
          legal_entity_id: "980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2",
          person_id: "071a2783-f752-42d9-bcfc-44ddc7eb923d",
          reason: nil,
          reason_description: nil,
          scope: "",
          signed_at: #DateTime<2019-01-20 12:24:36.442837Z>,
          start_date: ~D[2019-01-20],
          status: "active",
          updated_at: #DateTime<2019-01-30 12:24:36.455185Z>,
          updated_by: "8dac0fc6-04fd-4e62-9711-a85c0a42992d"
        }
      }
  """
  @spec update_declaration(binary, map) :: {:ok, declaration} | nil | {:error, %Ecto.Changeset{}}
  def update_declaration(id, %{} = params) do
    with %{} = declaration <- @read_repo.get(Declaration, id),
         {:ok, declaration} <- Declarations.update_declaration(declaration, params) do
      {:ok, DeclarationView.render("show.json", %{declaration: declaration})}
    end
  end

  @doc """
  Terminate declaration

  Available parameters:

  | Parameter           | Type                         | Example                                | Description                     |
  | :-----------------: | :--------------------------: | :------------------------------------: | :-----------------------------: |
  | updated_by          | `UUID`                       | `72b38c55-4fc9-4ab3-b656-1091af4c557c` | Required                        |
  | status              | `binary`                     | `active`                               | Required                        |
  | reason              | `binary`                     | `manual_person`                        | Required                        |
  | reason_description  | `binary`                     | `Person died`                          |                                 |

  ## Examples
      iex> OPS.Rpc.terminate_declaration("0042500e-6ac0-45fb-b82a-25f7857c49a8", %{"updated_by" => "11225aae-7ac0-45fb-b82a-25f7857c49b0"})
      {:ok,
        %{
          id: "cdb4a85b-f12c-46c6-b840-590467e26acf",
          created_by: "738c8cc1-ae9b-42a5-8660-4b7612b2b35c",
          declaration_number: "0",
          declaration_request_id: "382cc67b-7ade-4905-b8a9-0dfe2e9b9da0",
          division_id: "bb15bdde-ffd2-4683-8ca9-03c86b1e6846",
          employee_id: "f8cc0822-f214-4eea-a7d4-d03142901eb1",
          end_date: ~D[2019-01-21],
          inserted_at: #DateTime<2019-01-30 12:24:36.455175Z>,
          is_active: true,
          legal_entity_id: "980d4d01-3427-4f7f-bbdd-bd7c1b25b1e2",
          person_id: "071a2783-f752-42d9-bcfc-44ddc7eb923d",
          reason: nil,
          reason_description: nil,
          scope: "",
          signed_at: #DateTime<2019-01-20 12:24:36.442837Z>,
          start_date: ~D[2019-01-20],
          status: "active",
          updated_at: #DateTime<2019-01-30 12:24:36.455185Z>,
          updated_by: "8dac0fc6-04fd-4e62-9711-a85c0a42992d"
        }
      }
  """
  @spec terminate_declaration(binary, map) :: {:ok, declaration} | {:error, %Ecto.Changeset{}}
  def terminate_declaration(id, %{"updated_by" => _} = params) do
    with {:ok, declaration} <- Declarations.terminate_declaration(id, params) do
      {:ok, DeclarationView.render("show.json", %{declaration: declaration})}
    else
      %Changeset{} = changeset -> {:error, changeset}
      err -> err
    end
  end
end
