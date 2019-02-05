defmodule OPS.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  import Ecto.Query

  alias Core.Declarations
  alias Core.Declarations.Declaration
  alias Core.MedicationRequest
  alias Core.MedicationRequest.Search
  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.Changeset
  alias EView.Views.ValidationError
  alias OPS.Web.DeclarationView
  alias OPS.Web.MedicationRequestView

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

  @type medication_request :: %{
          id: Ecto.UUID.type(),
          request_number: binary(),
          created_at: Date.t(),
          started_at: Date.t(),
          ended_at: Date.t(),
          dispense_valid_from: Date.t(),
          dispense_valid_to: Date.t(),
          person_id: Ecto.UUID.type(),
          employee_id: Ecto.UUID.type(),
          division_id: Ecto.UUID.type(),
          medication_id: Ecto.UUID.type(),
          medication_qty: float(),
          status: binary(),
          is_active: boolean(),
          rejected_at: Date.t(),
          rejected_by: Ecto.UUID.type(),
          reject_reason: binary(),
          medication_request_requests_id: Ecto.UUID.type(),
          medical_program_id: Ecto.UUID.type(),
          inserted_by: Ecto.UUID.type(),
          updated_by: Ecto.UUID.type(),
          verification_code: binary(),
          legal_entity_id: Ecto.UUID.type(),
          intent: binary(),
          category: binary(),
          context: map(),
          dosage_instruction: list(map()),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
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

  @doc """
  Get medication request by id

  ## Examples
      iex> OPS.Rpc.medication_request_by_id("0469f379-ff2e-4a69-81e8-2cbfadf88d6b")
      %{
        category: "community",
        context: %{
          "identifier" => %{
            "type" => %{
              "coding" => [%{"code" => "encounter", "system" => "eHealth/resources"}]
            },
            "value" => "e3e2a3cc-388a-4555-9e16-a51ccb109724"
          }
        },
        created_at: ~D[2019-02-05],
        dispense_valid_from: ~D[2019-02-05],
        dispense_valid_to: ~D[2019-02-08],
        division_id: "406e4831-db4d-45a8-a26f-a246172705f5",
        dosage_instruction: [
          %{
            "additional_instruction" => [
              %{
                "coding" => [
                  %{
                    "code" => "311504000",
                    "system" => "eHealth/SNOMED/additional_dosage_instructions"
                  }
                ]
              }
            ],
            "as_needed_boolean" => true,
            "dose_and_rate" => %{
              "dose_range" => %{
                "high" => %{
                  "code" => "mg",
                  "system" => "eHealth/ucum/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "low" => %{
                  "code" => "mg",
                  "system" => "eHealth/ucum/units",
                  "unit" => "mg",
                  "value" => 13
                }
              },
              "rate_ratio" => %{
                "denominator" => %{
                  "code" => "mg",
                  "system" => "eHealth/ucum/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "numerator" => %{
                  "code" => "mg",
                  "system" => "eHealth/ucum/units",
                  "unit" => "mg",
                  "value" => 13
                }
              },
              "type" => %{
                "coding" => [
                  %{"code" => "ordered", "system" => "eHealth/dose_and_rate"}
                ]
              }
            },
            "max_dose_per_administration" => %{
              "code" => "mg",
              "system" => "eHealth/ucum/units",
              "unit" => "mg",
              "value" => 13
            },
            "max_dose_per_lifetime" => %{
              "code" => "mg",
              "system" => "eHealth/ucum/units",
              "unit" => "mg",
              "value" => 13
            },
            "max_dose_per_period" => %{
              "denominator" => %{
                "code" => "mg",
                "system" => "eHealth/ucum/units",
                "unit" => "mg",
                "value" => 13
              },
              "numerator" => %{
                "code" => "mg",
                "system" => "eHealth/ucum/units",
                "unit" => "mg",
                "value" => 13
              }
            },
            "method" => %{
              "coding" => [
                %{
                  "code" => "419747000",
                  "system" => "eHealth/SNOMED/administration_methods"
                }
              ]
            },
            "patient_instruction" => "0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015.  Do not exceed more than 4mg per day",
            "route" => %{
              "coding" => [
                %{"code" => "46713006", "system" => "eHealth/SNOMED/route_codes"}
              ]
            },
            "sequence" => 1,
            "site" => %{
              "coding" => [
                %{
                  "code" => "344001",
                  "system" => "eHealth/SNOMED/anatomical_structure_administration_site_codes"
                }
              ]
            },
            "text" => "0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015.  Do not exceed more than 4mg per day",
            "timing" => %{
              "code" => %{
                "coding" => [%{"code" => "AM", "system" => "TIMING_ABBREVIATION"}]
              },
              "event" => ["2017-04-20T19:14:13Z"],
              "repeat" => %{
                "bounds_duration" => %{
                  "code" => "d",
                  "system" => "eHealth/ucum/units",
                  "unit" => "days",
                  "value" => 10
                },
                "count" => 2,
                "count_max" => 4,
                "day_of_week" => ["mon"],
                "duration" => 4,
                "duration_max" => 6,
                "duration_unit" => "d",
                "frequency" => 1,
                "frequency_max" => 2,
                "offset" => 4,
                "period" => 4,
                "period_max" => 6,
                "period_unit" => "d",
                "time_of_day" => ["2017-04-20T19:14:13Z"],
                "when" => ["WAKE"]
              }
            }
          }
        ],
        employee_id: "43606f23-8a18-4902-93c4-0856cb2390ae",
        ended_at: ~D[2019-02-08],
        id: "0469f379-ff2e-4a69-81e8-2cbfadf88d6b",
        inserted_at: ~N[2019-02-05 11:29:57.064635],
        inserted_by: "34531e8a-ff95-4329-8de6-8c7bb9cb94a3",
        intent: "order",
        is_active: true,
        legal_entity_id: "be484454-c92e-4a1e-98ec-e1149b6c6bc3",
        medical_program_id: "f088cc19-ac1d-49fb-a95c-e659914960d9",
        medication_id: "7b8f8f3c-ce67-4b64-89b3-e0d31d0a1a2e",
        medication_qty: 10.0,
        medication_request_requests_id: "3dcaf3ee-6469-483f-bacd-befbf74716b8",
        person_id: "09564c9f-f4ef-4b8a-85c7-08ec48e5e562",
        reject_reason: "Помилка призначення. Несумісні препарати.",
        rejected_at: ~D[2019-02-08],
        rejected_by: "fb6c877f-1ed9-4589-b00a-023c69f8fca0",
        request_number: "0000-X2HA-157X-0214",
        started_at: ~D[2019-02-05],
        status: "EXPIRED",
        updated_at: ~N[2019-02-05 09:35:00.027131],
        updated_by: "4261eacf-8008-4e62-899f-de1e2f7065f0",
        verification_code: "7291"
      }
  """
  @spec medication_request_by_id(binary) :: medication_request | nil
  def medication_request_by_id(medication_request_id) do
    query = where(MedicationRequest, [mr], mr.id == ^medication_request_id)

    with %MedicationRequest{} = medication_request <- @read_repo.one(query) do
      MedicationRequestView.render("show.json", %{medication_request: medication_request})
    end
  end
end
