defmodule OPS.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  import Ecto.Query

  alias Core.Declarations
  alias Core.Declarations.Declaration
  alias Core.MedicationDispenses
  alias Core.MedicationRequest
  alias Core.MedicationRequest.Search
  alias Core.MedicationRequests
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.Changeset
  alias EView.Views.ValidationError
  alias OPS.Web.DeclarationView
  alias OPS.Web.MedicationDispenseView
  alias OPS.Web.MedicationRequestView
  alias Scrivener.Page

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @last_medication_request_dates_search_params ~w(
    person_id
    medication_id
    medical_program_id
    status
    started_at_to
  )

  @type page_medication_requests() :: %Page{
          entries: list(medication_request),
          page_number: number(),
          page_size: number(),
          total_entries: number(),
          total_pages: number()
        }

  @type page_medication_dispenses() :: %Page{
          entries: list(medication_dispense),
          page_number: number(),
          page_size: number(),
          total_entries: number(),
          total_pages: number()
        }

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

  @type medication_dispense :: %{
          id: Ecto.UUID.type(),
          details: list,
          dispensed_at: DateTime,
          dispensed_by: binary(),
          division_id: Ecto.UUID.type(),
          inserted_at: DateTime,
          inserted_by: Ecto.UUID.type(),
          is_active: boolean(),
          legal_entity_id: Ecto.UUID.type(),
          medical_program_id: Ecto.UUID.type(),
          medication_request: medication_request(),
          medication_request_id: Ecto.UUID.type(),
          party_id: Ecto.UUID.type(),
          payment_amount: float(),
          payment_id: Ecto.UUID.type(),
          status: binary(),
          updated_at: DateTime,
          updated_by: Ecto.UUID.type()
        }

  @doc """
  Searches medication request by given parameters (string key map) with maximum ended_at field.

  Available parameters (all of them are required):

  | Parameter           | Type                                                                   | Example                                | Description                                       |
  | :-----------------: | :--------------------------------------------------------------------: | :------------------------------------: | :-----------------------------------------------: |
  | person_id           | `UUID`                                                                 | `72b38c55-4fc9-4ab3-b656-1091af4c557c` |                                                   |
  | medication_id       | `binary` (lists are represented as binary with comma-separated values) | `64841249-7e59-4dfd-93ae-9a48b0f70595` or `7ac0d860-0430-4df5-9d56-0c267b64dfac,486bf854-9bae-496b-be13-1eeec5d57fed` |                                 |
  | medical_program_id  | `UUID`                                                                 | `c4b3bf60-8352-4454-a762-fc67847e3797` |                                                   |
  | status              | `binary` (lists are represented as binary with comma-separated values) | `ACTIVE` or `ACTIVE,COMPLETED`         |                                                   |
  | started_at_to       | `date`                                                                 | ~D[2018-12-18]                         | `started_at` attr less than `started_at_to` value |

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
    medication_ids = changes |> Map.get(:medication_id, "") |> String.split(",")
    started_at = Map.get(changes, :started_at_to)
    params = changes |> Map.drop(~w(status medication_id started_at_to)a) |> Map.to_list()

    result =
      MedicationRequest
      |> select([mr], %{"started_at" => mr.started_at, "ended_at" => mr.ended_at})
      |> where([mr], ^params)
      |> add_query_medication_ids(medication_ids)
      |> add_query_statuses(statuses)
      |> add_query_started_at(started_at)
      |> order_by([mr], desc: :ended_at)
      |> limit([mr], 1)
      |> @read_repo.all()

    if Enum.empty?(result), do: {:ok, nil}, else: {:ok, hd(result)}
  end

  defp search_last_medication_request_dates(%Ecto.Changeset{valid?: false} = changeset) do
    {:error, ValidationError.render("422.query.json", changeset)}
  end

  defp add_query_medication_ids(query, [""]), do: query
  defp add_query_medication_ids(query, medication_ids), do: where(query, [mr], mr.medication_id in ^medication_ids)

  defp add_query_statuses(query, [""]), do: query
  defp add_query_statuses(query, statuses), do: where(query, [mr], mr.status in ^statuses)

  defp add_query_started_at(query, nil), do: query
  defp add_query_started_at(query, started_at), do: where(query, [mr], mr.started_at < ^started_at)

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

  @doc """
  Search  requests for doctor

  ## Examples
      iex> OPS.Rpc.medication_requests(%{"legal_entity_id" => "4d958f02-c2c3-4228-8ea3-ac4a7a7a286a"})
      %Scrivener.Page{
        entries: [
          %{
            category: "community",
            context: %{
              "identifier" => %{
                "type" => %{
                  "coding" => [
                    %{
                      "code" => "encounter",
                      "system" => "eHealth/resources"
                    }
                  ]
                },
                "value" => "b766941c-6cf0-42e2-888f-595a6658e1b4"
              }
            },
            created_at: ~D[2019-04-17],
            dispense_valid_from: ~D[2019-04-17],
            dispense_valid_to: ~D[2019-04-17],
            division_id: "dc1fa9a2-46f1-4fcc-ae33-68c21f9c549a",
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
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    },
                    "low" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    }
                  },
                  "rate_ratio" => %{
                    "denominator" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    },
                    "numerator" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    }
                  },
                  "type" => %{
                    "coding" => [
                      %{
                        "code" => "'ordered'",
                        "system" => "eHealth/dose_and_rate"
                      }
                    ]
                  }
                },
                "max_dose_per_administration" => %{
                  "code" => "mg",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "max_dose_per_lifetime" => %{
                  "code" => "mg",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "max_dose_per_period" => %{
                  "denominator" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  },
                  "numerator" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
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
                    %{
                      "code" => "46713006",
                      "system" => "eHealth/SNOMED/route_codes"
                    }
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
                    "coding" => [
                      %{
                        "code" => "patient",
                        "system" => "eHealth/timing_abbreviation"
                      }
                    ]
                  },
                  "event" => ["2017-04-20T19:14:13Z"],
                  "repeat" => %{
                    "bounds_duration" => %{
                      "code" => "d",
                      "system" => "http://unitsofmeasure.org",
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
            employee_id: "bed1bc93-ef2e-4ca0-9f07-e58f52b312c6",
            ended_at: ~D[2019-04-17],
            id: "e9b4d92a-dc7c-483f-9ae9-f4b57bc89c4d",
            inserted_at: #DateTime<2019-04-17 12:50:22Z>,
            inserted_by: "1630ef83-1b03-4d15-b03f-33f6b13a44b7",
            intent: "order",
            is_active: true,
            legal_entity_id: "4d958f02-c2c3-4228-8ea3-ac4a7a7a286a",
            medical_program_id: nil,
            medication_id: "85e70454-6fd6-4a3d-8e5f-78fdf657d24b",
            medication_qty: 0.0,
            medication_request_requests_id: "64878c2f-9960-4536-a92a-6f8571b0f4ed",
            person_id: "13630bed-1a1c-4854-afaf-ff50cf5164d9",
            reject_reason: nil,
            rejected_at: nil,
            rejected_by: nil,
            request_number: "0.7320575476812545",
            started_at: ~D[2019-04-17],
            status: "ACTIVE",
            updated_at: #DateTime<2019-04-17 12:50:22Z>,
            updated_by: "649ae8e4-eea3-46d5-b19f-747b9cdb2c39",
            verification_code: nil
          }
        ],
        page_number: 1,
        page_size: 50,
        total_entries: 1,
        total_pages: 1
      }
  """
  @spec medication_requests(map) :: {:error, any()} | page_medication_requests
  def medication_requests(params) do
    with %Page{} = page <- MedicationRequests.list(params) do
      %Page{page | entries: MedicationRequestView.render("index.json", %{medication_requests: page.entries})}
    end
  end

  @doc """
  Search medication requests for doctor

  ## Examples
      iex> OPS.Rpc.doctor_medication_requests(%{"legal_entity_id" => "4d958f02-c2c3-4228-8ea3-ac4a7a7a286a"})
      %Scrivener.Page{
        entries: [
          %{
            category: "community",
            context: %{
              "identifier" => %{
                "type" => %{
                  "coding" => [
                    %{
                      "code" => "encounter",
                      "system" => "eHealth/resources"
                    }
                  ]
                },
                "value" => "b766941c-6cf0-42e2-888f-595a6658e1b4"
              }
            },
            created_at: ~D[2019-04-17],
            dispense_valid_from: ~D[2019-04-17],
            dispense_valid_to: ~D[2019-04-17],
            division_id: "dc1fa9a2-46f1-4fcc-ae33-68c21f9c549a",
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
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    },
                    "low" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    }
                  },
                  "rate_ratio" => %{
                    "denominator" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    },
                    "numerator" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    }
                  },
                  "type" => %{
                    "coding" => [
                      %{
                        "code" => "'ordered'",
                        "system" => "eHealth/dose_and_rate"
                      }
                    ]
                  }
                },
                "max_dose_per_administration" => %{
                  "code" => "mg",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "max_dose_per_lifetime" => %{
                  "code" => "mg",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "max_dose_per_period" => %{
                  "denominator" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  },
                  "numerator" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
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
                    %{
                      "code" => "46713006",
                      "system" => "eHealth/SNOMED/route_codes"
                    }
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
                    "coding" => [
                      %{
                        "code" => "patient",
                        "system" => "eHealth/timing_abbreviation"
                      }
                    ]
                  },
                  "event" => ["2017-04-20T19:14:13Z"],
                  "repeat" => %{
                    "bounds_duration" => %{
                      "code" => "d",
                      "system" => "http://unitsofmeasure.org",
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
            employee_id: "bed1bc93-ef2e-4ca0-9f07-e58f52b312c6",
            ended_at: ~D[2019-04-17],
            id: "e9b4d92a-dc7c-483f-9ae9-f4b57bc89c4d",
            inserted_at: #DateTime<2019-04-17 12:50:22Z>,
            inserted_by: "1630ef83-1b03-4d15-b03f-33f6b13a44b7",
            intent: "order",
            is_active: true,
            legal_entity_id: "4d958f02-c2c3-4228-8ea3-ac4a7a7a286a",
            medical_program_id: nil,
            medication_id: "85e70454-6fd6-4a3d-8e5f-78fdf657d24b",
            medication_qty: 0.0,
            medication_request_requests_id: "64878c2f-9960-4536-a92a-6f8571b0f4ed",
            person_id: "13630bed-1a1c-4854-afaf-ff50cf5164d9",
            reject_reason: nil,
            rejected_at: nil,
            rejected_by: nil,
            request_number: "0.7320575476812545",
            started_at: ~D[2019-04-17],
            status: "ACTIVE",
            updated_at: #DateTime<2019-04-17 12:50:22Z>,
            updated_by: "649ae8e4-eea3-46d5-b19f-747b9cdb2c39",
            verification_code: nil
          }
        ],
        page_number: 1,
        page_size: 50,
        total_entries: 1,
        total_pages: 1
      }
  """
  @spec doctor_medication_requests(map) :: {:error, any()} | page_medication_requests
  def doctor_medication_requests(params) do
    with %Page{} = page <- MedicationRequests.doctor_list(params) do
      %Page{page | entries: MedicationRequestView.render("index.json", %{medication_requests: page.entries})}
    end
  end

  @doc """
  Get medication request qualified medication ids by patient_id, started_at, ended_at

  ## Examples
      iex> OPS.Rpc.qualify_medication_requests(%{
        "ended_at" => ~D[2019-04-25],
        "person_id" => "ad3402eb-2caa-45a3-b96e-fe837b21f767",
        "started_at" => ~D[2019-04-20]
      })
      {:ok, ["5327b993-071d-49b1-b04f-8cb0401e49de"]}
  """
  @spec qualify_medication_requests(map) :: {:error, any()} | {:ok, list}
  def qualify_medication_requests(params) do
    with {:ok, ids} <- MedicationRequests.qualify_list(params) do
      {:ok, MedicationRequestView.render("qualify_list.json", %{ids: ids})}
    end
  end

  @doc """
  Get medication request prequalified medication ids by patient_id, started_at, ended_at

  ## Examples
      iex> OPS.Rpc.prequalify_medication_requests(%{
        "ended_at" => ~D[2019-04-25],
        "person_id" => "ad3402eb-2caa-45a3-b96e-fe837b21f767",
        "started_at" => ~D[2019-04-20]
      })
      {:ok, ["5327b993-071d-49b1-b04f-8cb0401e49de"]}
  """
  @spec prequalify_medication_requests(map) :: {:error, any()} | {:ok, list}
  def prequalify_medication_requests(params) do
    with {:ok, ids} <- MedicationRequests.prequalify_list(params) do
      {:ok, MedicationRequestView.render("qualify_list.json", %{ids: ids})}
    end
  end

  @doc """
  Create medication request

  ## Examples
      iex> OPS.Rpc.create_medication_request(%{
        created_at: ~D[2019-04-20],
        division_id: "84ea121b-567c-4bb9-9145-910f89a6c1e4",
        employee_id: "cd7fc613-c912-48ec-a5e8-3c96bd75766c",
        ended_at: ~D[2019-04-20],
        id: "f3cd2f3f-e474-4d38-a1c8-cfb8e11d1ff2",
        inserted_by: "a7b846c3-0f44-495b-ab95-1e88888ec3c9",
        legal_entity_id: "b41e406c-85ef-4e6a-85ee-1819bd0f0533",
        medication_id: "193a1c08-5ca2-436d-a258-e623c210e299",
        medication_qty: 20,
        medication_request_requests_id: "7e17c562-bf5b-4367-89b5-b7dc2d9431f8",
        person_id: "51320dc8-a583-4de6-8456-c3e2075d6c6b",
        request_number: "1234",
        started_at: ~D[2019-04-20],
        updated_by: "1ce4e44e-9f8b-4c57-9a44-63c410510bc3"
      })
      {:ok,
      %{
        category: "community",
        context: nil,
        created_at: ~D[2019-04-20],
        dispense_valid_from: nil,
        dispense_valid_to: nil,
        division_id: "84ea121b-567c-4bb9-9145-910f89a6c1e4",
        dosage_instruction: nil,
        employee_id: "cd7fc613-c912-48ec-a5e8-3c96bd75766c",
        ended_at: ~D[2019-04-20],
        id: "f3cd2f3f-e474-4d38-a1c8-cfb8e11d1ff2",
        inserted_at: #DateTime<2019-04-20 18:53:23Z>,
        inserted_by: "a7b846c3-0f44-495b-ab95-1e88888ec3c9",
        intent: "order",
        is_active: true,
        legal_entity_id: "b41e406c-85ef-4e6a-85ee-1819bd0f0533",
        medical_program_id: nil,
        medication_id: "193a1c08-5ca2-436d-a258-e623c210e299",
        medication_qty: 20.0,
        medication_request_requests_id: "7e17c562-bf5b-4367-89b5-b7dc2d9431f8",
        person_id: "51320dc8-a583-4de6-8456-c3e2075d6c6b",
        reject_reason: nil,
        rejected_at: nil,
        rejected_by: nil,
        request_number: "1234",
        started_at: ~D[2019-04-20],
        status: "ACTIVE",
        updated_at: #DateTime<2019-04-20 18:53:23Z>,
        updated_by: "1ce4e44e-9f8b-4c57-9a44-63c410510bc3",
        verification_code: nil
      }}
  """
  @spec create_medication_request(map) :: {:error, any()} | {:ok, medication_request}
  def create_medication_request(params) do
    with {:ok, medication_request} <- MedicationRequests.create(%{"medication_request" => params}) do
      {:ok, MedicationRequestView.render("show.json", %{medication_request: medication_request})}
    end
  end

  @doc """
  Update medication request

  ## Examples
      iex> OPS.Rpc.update_medication_request(d7280856-66c7-40c7-b969-01c7bb30cfbd, %{
        status: "COMPLETED",
        updated_by: "2cd42850-64d7-4e3b-9cea-c77d7982f6ec"
      })
      {:ok,
      %{
        category: "community",
        context: %{
          "identifier" => %{
            "type" => %{
              "coding" => [%{"code" => "encounter", "system" => "eHealth/resources"}]
            },
            "value" => "512b79dd-2ff3-4fcb-89e6-ff95bfd31575"
          }
        },
        created_at: ~D[2019-04-20],
        dispense_valid_from: ~D[2019-04-20],
        dispense_valid_to: ~D[2019-04-20],
        division_id: "354cf351-318c-48c7-b4ad-db53ff95f827",
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
                  "comparator" => ">",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "low" => %{
                  "code" => "mg",
                  "comparator" => ">",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                }
              },
              "rate_ratio" => %{
                "denominator" => %{
                  "code" => "mg",
                  "comparator" => ">",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "numerator" => %{
                  "code" => "mg",
                  "comparator" => ">",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                }
              },
              "type" => %{
                "coding" => [
                  %{"code" => "'ordered'", "system" => "eHealth/dose_and_rate"}
                ]
              }
            },
            "max_dose_per_administration" => %{
              "code" => "mg",
              "system" => "eHealth/units",
              "unit" => "mg",
              "value" => 13
            },
            "max_dose_per_lifetime" => %{
              "code" => "mg",
              "system" => "eHealth/units",
              "unit" => "mg",
              "value" => 13
            },
            "max_dose_per_period" => %{
              "denominator" => %{
                "code" => "mg",
                "comparator" => ">",
                "system" => "eHealth/units",
                "unit" => "mg",
                "value" => 13
              },
              "numerator" => %{
                "code" => "mg",
                "comparator" => ">",
                "system" => "eHealth/units",
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
                "coding" => [
                  %{"code" => "patient", "system" => "eHealth/timing_abbreviation"}
                ]
              },
              "event" => ["2017-04-20T19:14:13Z"],
              "repeat" => %{
                "bounds_duration" => %{
                  "code" => "d",
                  "system" => "http://unitsofmeasure.org",
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
        employee_id: "8b761d3b-fd59-46af-9fdd-3752b0de35f3",
        ended_at: ~D[2019-04-20],
        id: "d7280856-66c7-40c7-b969-01c7bb30cfbd",
        inserted_at: #DateTime<2019-04-20 20:06:57Z>,
        inserted_by: "9242e638-9ffc-46fa-8c26-c1d5773ff0e5",
        intent: "order",
        is_active: true,
        legal_entity_id: "9875366c-850b-4927-8e6b-6a4266c71506",
        medical_program_id: nil,
        medication_id: "458c82c7-0597-422a-bc1e-7f726c1ad614",
        medication_qty: 0.0,
        medication_request_requests_id: "527f9ab6-21da-4d17-892a-dfc91ade5928",
        person_id: "149184bf-4ddc-4856-8ba0-1ee573352afb",
        reject_reason: nil,
        rejected_at: nil,
        rejected_by: nil,
        request_number: "0.8005479829613573",
        started_at: ~D[2019-04-20],
        status: "COMPLETED",
        updated_at: #DateTime<2019-04-20 20:06:58Z>,
        updated_by: "2cd42850-64d7-4e3b-9cea-c77d7982f6ec",
        verification_code: nil
      }}
  """
  @spec update_medication_request(binary, map) :: {:error, any()} | {:ok, medication_request} | nil
  def update_medication_request(id, params) do
    with %Page{entries: [medication_request]} <- MedicationRequests.list(%{"id" => id}),
         {:ok, medication_request} <- MedicationRequests.update(medication_request, params) do
      {:ok, MedicationRequestView.render("show.json", %{medication_request: medication_request})}
    else
      %Page{entries: []} -> nil
      error -> error
    end
  end

  @doc """
  Search medication dispenses

  ## Examples
      iex> OPS.Rpc.medication_dispenses(%{"legal_entity_id" => "805cfb96-625f-460a-879d-f225e58383ce"})
      %Scrivener.Page{
        entries: [
          %{
            details: [],
            dispensed_at: ~D[2019-04-19],
            dispensed_by: "John Doe2",
            division_id: "c511b4fc-b6fa-45be-a2f7-4a9dff2423d0",
            id: "e20909bb-1315-45ca-aa6c-ed3a62bb835c",
            inserted_at: #DateTime<2019-04-19 06:47:01Z>,
            inserted_by: "9d977c83-5c6f-4b3a-9bd5-fc102359ba3b",
            is_active: true,
            legal_entity_id: "805cfb96-625f-460a-879d-f225e58383ce",
            medical_program_id: "4d4b8abe-3677-44b5-90fd-3f7bcdf37ead",
            medication_request: %{
              category: "community",
              context: %{
                "identifier" => %{
                  "type" => %{
                    "coding" => [
                      %{"code" => "encounter", "system" => "eHealth/resources"}
                    ]
                  },
                  "value" => "9c10cd7d-141d-41c7-9098-e9b3dfe31648"
                }
              },
              created_at: ~D[2019-04-19],
              dispense_valid_from: ~D[2019-04-19],
              dispense_valid_to: ~D[2019-04-19],
              division_id: "ecd03416-f31a-44fc-86b7-46b35a325dc5",
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
                        "comparator" => ">",
                        "system" => "eHealth/units",
                        "unit" => "mg",
                        "value" => 13
                      },
                      "low" => %{
                        "code" => "mg",
                        "comparator" => ">",
                        "system" => "eHealth/units",
                        "unit" => "mg",
                        "value" => 13
                      }
                    },
                    "rate_ratio" => %{
                      "denominator" => %{
                        "code" => "mg",
                        "comparator" => ">",
                        "system" => "eHealth/units",
                        "unit" => "mg",
                        "value" => 13
                      },
                      "numerator" => %{
                        "code" => "mg",
                        "comparator" => ">",
                        "system" => "eHealth/units",
                        "unit" => "mg",
                        "value" => 13
                      }
                    },
                    "type" => %{
                      "coding" => [
                        %{"code" => "'ordered'", "system" => "eHealth/dose_and_rate"}
                      ]
                    }
                  },
                  "max_dose_per_administration" => %{
                    "code" => "mg",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  },
                  "max_dose_per_lifetime" => %{
                    "code" => "mg",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  },
                  "max_dose_per_period" => %{
                    "denominator" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
                      "unit" => "mg",
                      "value" => 13
                    },
                    "numerator" => %{
                      "code" => "mg",
                      "comparator" => ">",
                      "system" => "eHealth/units",
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
                      %{
                        "code" => "46713006",
                        "system" => "eHealth/SNOMED/route_codes"
                      }
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
                      "coding" => [
                        %{
                          "code" => "patient",
                          "system" => "eHealth/timing_abbreviation"
                        }
                      ]
                    },
                    "event" => ["2017-04-20T19:14:13Z"],
                    "repeat" => %{
                      "bounds_duration" => %{
                        "code" => "d",
                        "system" => "http://unitsofmeasure.org",
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
                      ...
                    }
                  }
                }
              ],
              employee_id: "67956476-e6dd-4f05-92ed-3857771b574d",
              ended_at: ~D[2019-04-19],
              id: "c6de8e9a-ff3c-4428-9615-7249e87119d0",
              inserted_at: #DateTime<2019-04-19 06:47:01Z>,
              inserted_by: "4ff0a378-c83c-46cb-ba07-59902cc08042",
              intent: "order",
              is_active: true,
              legal_entity_id: "28e9f738-123c-4432-9638-f50b87f90b28",
              medical_program_id: nil,
              medication_id: "7a2c59fb-053e-4dcd-a714-2e4310396da5",
              medication_qty: 0.0,
              medication_request_requests_id: "e422f9b4-195d-4751-938f-280d120803fb",
              person_id: "7da225ef-740e-4926-b3e6-f0276efdad07",
              reject_reason: nil,
              rejected_at: nil,
              rejected_by: nil,
              request_number: "0.3460077299229586",
              started_at: ~D[2019-04-19],
              status: "ACTIVE",
              updated_at: #DateTime<2019-04-19 06:47:01Z>,
              updated_by: "40848a8b-5f05-4100-9e9c-27b343891e0d",
              verification_code: nil
            },
            medication_request_id: "c6de8e9a-ff3c-4428-9615-7249e87119d0",
            party_id: "ecc396ff-df3a-4999-804d-5c920207a824",
            payment_amount: nil,
            payment_id: "19955648-75e7-4ad4-a9ef-51d285b3365d",
            status: "NEW",
            updated_at: #DateTime<2019-04-19 06:47:01Z>,
            updated_by: "885b6153-bf79-465b-910a-53a257838712"
          }
        ],
        page_number: 1,
        page_size: 50,
        total_entries: 1,
        total_pages: 1
      }
  """
  @spec medication_dispenses(map) :: {:error, any()} | page_medication_dispenses
  def medication_dispenses(params) do
    with %Page{} = page <- MedicationDispenses.list(params) do
      %Page{page | entries: MedicationDispenseView.render("index.json", %{medication_dispenses: page.entries})}
    end
  end

  @doc """
  Create medication dispense

  ## Examples
      iex> OPS.Rpc.create_medication_dispense(%{
        dispensed_at: ~D[2019-04-22],
        division_id: "68da803d-5b38-4bdf-a461-a690a93f16a5",
        id: "633518c9-ceba-4069-8719-cb5f4baf16aa",
        inserted_by: "4d68ee39-685a-4419-b5a1-7ec23374d874",
        is_active: true,
        legal_entity_id: "76844a95-623b-468b-975c-ed23ec66f1e9",
        medication_request_id: "d71ec39d-bd30-4cf6-a8ed-5b741278b59f",
        party_id: "cfc9c566-27c4-49fc-b0d4-41926d234c91",
        status: "NEW",
        updated_by: "ab3c8df7-9f65-4821-a421-fc843c6a8530"
      })
      {:ok,
      %{
        details: [],
        dispensed_at: ~D[2019-04-22],
        dispensed_by: nil,
        division_id: "68da803d-5b38-4bdf-a461-a690a93f16a5",
        id: "633518c9-ceba-4069-8719-cb5f4baf16aa",
        inserted_at: #DateTime<2019-04-22 07:24:05Z>,
        inserted_by: "4d68ee39-685a-4419-b5a1-7ec23374d874",
        is_active: true,
        legal_entity_id: "76844a95-623b-468b-975c-ed23ec66f1e9",
        medical_program_id: nil,
        medication_request: nil,
        medication_request_id: "d71ec39d-bd30-4cf6-a8ed-5b741278b59f",
        party_id: "cfc9c566-27c4-49fc-b0d4-41926d234c91",
        payment_amount: nil,
        payment_id: nil,
        status: "NEW",
        updated_at: #DateTime<2019-04-22 07:24:05Z>,
        updated_by: "ab3c8df7-9f65-4821-a421-fc843c6a8530"
      }}
  """
  @spec create_medication_dispense(map) :: {:error, any()} | {:ok, medication_dispense}
  def create_medication_dispense(params) do
    with {:ok, medication_dispense} <- MedicationDispenses.create(params) do
      {:ok, MedicationDispenseView.render("show.json", %{medication_dispense: medication_dispense})}
    end
  end

  @doc """
  Update medication dispense

  ## Examples
      iex> OPS.Rpc.update_medication_dispense(
        "18e9ff3c-be22-4785-99b7-a4408da2c0a4",
        %{
          status: "PROCESSED",
          updated_by: "a5250c22-30b6-4921-a7e6-21fe02a2e6aa"
        }
      )
      {:ok,
      %{
        details: [],
        dispensed_at: ~D[2019-04-22],
        dispensed_by: "John Doe0",
        division_id: "8c27163e-75d4-43fc-80b0-ed6f185d1653",
        id: "18e9ff3c-be22-4785-99b7-a4408da2c0a4",
        inserted_at: #DateTime<2019-04-22 07:26:25Z>,
        inserted_by: "a3434fa9-814c-49b2-b6ef-1e3213c7a215",
        is_active: true,
        legal_entity_id: "40e526fd-67f3-47d0-9f1a-acb631bf65ae",
        medical_program_id: "541abd53-e1e3-42ab-8290-ab967463c44f",
        medication_request: %{
          category: "community",
          context: %{
            "identifier" => %{
              "type" => %{
                "coding" => [
                  %{"code" => "encounter", "system" => "eHealth/resources"}
                ]
              },
              "value" => "0f15b39c-3db0-460f-9edc-3bf6abed9a25"
            }
          },
          created_at: ~D[2019-04-22],
          dispense_valid_from: ~D[2019-04-22],
          dispense_valid_to: ~D[2019-04-22],
          division_id: "b28ad7f7-0e9a-4a04-8d06-0da88be44e85",
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
                    "comparator" => ">",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  },
                  "low" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  }
                },
                "rate_ratio" => %{
                  "denominator" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  },
                  "numerator" => %{
                    "code" => "mg",
                    "comparator" => ">",
                    "system" => "eHealth/units",
                    "unit" => "mg",
                    "value" => 13
                  }
                },
                "type" => %{
                  "coding" => [
                    %{"code" => "'ordered'", "system" => "eHealth/dose_and_rate"}
                  ]
                }
              },
              "max_dose_per_administration" => %{
                "code" => "mg",
                "system" => "eHealth/units",
                "unit" => "mg",
                "value" => 13
              },
              "max_dose_per_lifetime" => %{
                "code" => "mg",
                "system" => "eHealth/units",
                "unit" => "mg",
                "value" => 13
              },
              "max_dose_per_period" => %{
                "denominator" => %{
                  "code" => "mg",
                  "comparator" => ">",
                  "system" => "eHealth/units",
                  "unit" => "mg",
                  "value" => 13
                },
                "numerator" => %{
                  "code" => "mg",
                  "comparator" => ">",
                  "system" => "eHealth/units",
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
                  "coding" => [
                    %{"code" => "patient", "system" => "eHealth/timing_abbreviation"}
                  ]
                },
                "event" => ["2017-04-20T19:14:13Z"],
                "repeat" => %{
                  "bounds_duration" => %{
                    "code" => "d",
                    "system" => "http://unitsofmeasure.org",
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
                  ...
                }
              }
            }
          ],
          employee_id: "16099f5f-abcc-41ee-8a75-db78587d327d",
          ended_at: ~D[2019-04-22],
          id: "4d499021-d752-4fcf-af57-bf01e26b5b13",
          inserted_at: #DateTime<2019-04-22 07:26:25Z>,
          inserted_by: "a1f83b8b-1c91-4f72-b5fd-fed57dcb2023",
          intent: "order",
          is_active: true,
          legal_entity_id: "04704ab6-2a24-403c-ace3-5499a748d305",
          medical_program_id: nil,
          medication_id: "b75d70b3-e2cd-40ed-8952-4e246582b027",
          medication_qty: 0.0,
          medication_request_requests_id: "7a9871fc-3591-4713-84ac-ad104a8dde71",
          person_id: "943b522d-2969-4ceb-aaf5-b5e0d3b28b18",
          reject_reason: nil,
          rejected_at: nil,
          rejected_by: nil,
          request_number: "0.00897163491406282",
          started_at: ~D[2019-04-22],
          status: "ACTIVE",
          updated_at: #DateTime<2019-04-22 07:26:25Z>,
          updated_by: "99b7a856-19ff-4509-befc-e2309ba9369c",
          verification_code: nil
        },
        medication_request_id: "4d499021-d752-4fcf-af57-bf01e26b5b13",
        party_id: "50d5978d-6663-45b2-952c-f991225d2261",
        payment_amount: nil,
        payment_id: "c4de464c-9bd7-4a30-830a-7190ca94fe0c",
        status: "PROCESSED",
        updated_at: #DateTime<2019-04-22 07:26:25Z>,
        updated_by: "a5250c22-30b6-4921-a7e6-21fe02a2e6aa"
      }}
  """
  @spec update_medication_dispense(binary, map) :: {:error, any()} | {:ok, medication_dispense} | nil
  def update_medication_dispense(id, params) do
    with %Page{entries: [medication_dispense]} <- MedicationDispenses.list(%{"id" => id}),
         {:ok, medication_dispense} <- MedicationDispenses.update(medication_dispense, params) do
      {:ok, MedicationDispenseView.render("show.json", %{medication_dispense: medication_dispense})}
    else
      %Page{entries: []} -> nil
      error -> error
    end
  end
end
