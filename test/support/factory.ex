defmodule OPS.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: OPS.Repo

  alias OPS.Declarations.Declaration
  alias OPS.MedicationDispenses.MedicationDispense
  alias OPS.MedicationRequests.MedicationRequest
  alias OPS.MedicationDispense.Details
  alias Ecto.UUID

  def declaration_factory do
    start_date = NaiveDateTime.utc_now() |> NaiveDateTime.add(days_to_seconds(-10), :seconds)
    end_date = NaiveDateTime.add(start_date, days_to_seconds(1), :seconds)

    %Declaration{
      id: UUID.generate(),
      declaration_request_id: UUID.generate(),
      start_date: start_date,
      end_date: end_date,
      status: Declaration.status(:active),
      signed_at: start_date,
      created_by: UUID.generate(),
      updated_by: UUID.generate(),
      employee_id: UUID.generate(),
      person_id: UUID.generate(),
      division_id: UUID.generate(),
      legal_entity_id: UUID.generate(),
      is_active: true,
      scope: "",
      seed: "some seed",
      declaration_number: sequence("")
    }
  end

  def medication_dispense_factory do
    %MedicationDispense{
      id: UUID.generate(),
      status: MedicationDispense.status(:new),
      inserted_by: UUID.generate(),
      updated_by: UUID.generate(),
      is_active: true,
      dispensed_by: sequence("John Doe"),
      dispensed_at: to_string(Date.utc_today()),
      party_id: UUID.generate(),
      legal_entity_id: UUID.generate(),
      payment_id: UUID.generate(),
      division_id: UUID.generate(),
      medical_program_id: UUID.generate(),
      medication_request: build(:medication_request)
    }
  end

  def medication_request_factory do
    %MedicationRequest{
      id: UUID.generate(),
      status: MedicationRequest.status(:active),
      inserted_by: UUID.generate(),
      updated_by: UUID.generate(),
      is_active: true,
      person_id: UUID.generate(),
      employee_id: UUID.generate(),
      division_id: UUID.generate(),
      medication_id: UUID.generate(),
      created_at: NaiveDateTime.utc_now(),
      started_at: NaiveDateTime.utc_now(),
      ended_at: NaiveDateTime.utc_now(),
      dispense_valid_from: Date.utc_today(),
      dispense_valid_to: Date.utc_today(),
      medication_qty: 0,
      medication_request_requests_id: UUID.generate(),
      request_number: to_string(:rand.uniform()),
      legal_entity_id: UUID.generate(),
      intent: "order",
      category: "community",
      context: medical_events_context(),
      dosage_instruction: medical_events_dosage_instruction()
    }
  end

  def medication_dispense_details_factory do
    %Details{
      medication_id: UUID.generate(),
      medication_qty: 10,
      sell_price: 150,
      reimbursement_amount: 100,
      medication_dispense_id: UUID.generate(),
      sell_amount: 30,
      discount_amount: 0
    }
  end

  defp to_float(number) when is_integer(number), do: number + 0.0
  defp days_to_seconds(count), do: 24 * 60 * 60 * count

  defp medical_events_context do
    %{
      "identifier" => %{
        "type" => %{
          "coding" => [
            %{
              "system" => "eHealth/resources",
              "code" => "encounter"
            }
          ]
        },
        "value" => UUID.generate()
      }
    }
  end

  defp medical_events_dosage_instruction do
    [
      %{
        "sequence" => 1,
        "text" =>
          "0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015.  Do not exceed more than 4mg per day",
        "additional_instruction" => [
          %{
            "coding" => [
              %{
                "system" => "eHealth/SNOMED/additional_dosage_instructions",
                "code" => "311504000"
              }
            ]
          }
        ],
        "patient_instruction" =>
          "0.25mg PO every 6-12 hours as needed for menses from Jan 15-20, 2015.  Do not exceed more than 4mg per day",
        "timing" => %{
          "event" => [
            "2017-04-20T19:14:13Z"
          ],
          "repeat" => %{
            "bounds_duration" => %{
              "value" => 10,
              "unit" => "days",
              "system" => "http://unitsofmeasure.org",
              "code" => "d"
            },
            "count" => 2,
            "count_max" => 4,
            "duration" => 4,
            "duration_max" => 6,
            "duration_unit" => "d",
            "frequency" => 1,
            "frequency_max" => 2,
            "period" => 4,
            "period_max" => 6,
            "period_unit" => "d",
            "day_of_week" => [
              "mon"
            ],
            "time_of_day" => [
              "2017-04-20T19:14:13Z"
            ],
            "when" => [
              "WAKE"
            ],
            "offset" => 4
          },
          "code" => %{
            "coding" => [
              %{
                "system" => "eHealth/timing_abbreviation",
                "code" => "patient"
              }
            ]
          }
        },
        "as_needed_boolean" => true,
        "site" => %{
          "coding" => [
            %{
              "system" => "eHealth/SNOMED/anatomical_structure_administration_site_codes",
              "code" => "344001"
            }
          ]
        },
        "route" => %{
          "coding" => [
            %{
              "system" => "eHealth/SNOMED/route_codes",
              "code" => "46713006"
            }
          ]
        },
        "method" => %{
          "coding" => [
            %{
              "system" => "eHealth/SNOMED/administration_methods",
              "code" => "419747000"
            }
          ]
        },
        "dose_and_rate" => %{
          "type" => %{
            "coding" => [
              %{
                "system" => "eHealth/dose_and_rate",
                "code" => "'ordered'"
              }
            ]
          },
          "dose_range" => %{
            "low" => %{
              "value" => 13,
              "comparator" => ">",
              "unit" => "mg",
              "system" => "eHealth/units",
              "code" => "mg"
            },
            "high" => %{
              "value" => 13,
              "comparator" => ">",
              "unit" => "mg",
              "system" => "eHealth/units",
              "code" => "mg"
            }
          },
          "rate_ratio" => %{
            "numerator" => %{
              "value" => 13,
              "comparator" => ">",
              "unit" => "mg",
              "system" => "eHealth/units",
              "code" => "mg"
            },
            "denominator" => %{
              "value" => 13,
              "comparator" => ">",
              "unit" => "mg",
              "system" => "eHealth/units",
              "code" => "mg"
            }
          }
        },
        "max_dose_per_period" => %{
          "numerator" => %{
            "value" => 13,
            "comparator" => ">",
            "unit" => "mg",
            "system" => "eHealth/units",
            "code" => "mg"
          },
          "denominator" => %{
            "value" => 13,
            "comparator" => ">",
            "unit" => "mg",
            "system" => "eHealth/units",
            "code" => "mg"
          }
        },
        "max_dose_per_administration" => %{
          "value" => 13,
          "unit" => "mg",
          "system" => "eHealth/units",
          "code" => "mg"
        },
        "max_dose_per_lifetime" => %{
          "value" => 13,
          "unit" => "mg",
          "system" => "eHealth/units",
          "code" => "mg"
        }
      }
    ]
  end
end
