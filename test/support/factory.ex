defmodule OPS.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: OPS.Repo

  alias OPS.Declarations.Declaration
  alias OPS.MedicationDispenses.MedicationDispense
  alias OPS.MedicationRequests.MedicationRequest
  alias OPS.MedicationDispense.Details
  alias OPS.Contracts.Contract
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
      legal_entity_id: UUID.generate()
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

  def contract_factory do
    %Contract{
      id: UUID.generate(),
      start_date: Date.utc_today(),
      end_date: Date.utc_today() |> Date.add(60),
      status: Contract.status(:verified),
      contractor_legal_entity_id: UUID.generate(),
      contractor_owner_id: UUID.generate(),
      contractor_base: "на підставі закону про Медичне обслуговування населення",
      contractor_payment_details: %{
        bank_name: "Банк номер 1",
        MFO: "351005",
        payer_account: "32009102701026"
      },
      contractor_rmsp_amount: Enum.random(50_000..100_000),
      external_contractor_flag: true,
      external_contractors: [
        %{
          legal_entity: %{
            id: UUID.generate(),
            name: "Клініка Ноунейм"
          },
          contract: %{
            number: "1234567",
            issued_at: NaiveDateTime.utc_now(),
            expires_at: NaiveDateTime.add(NaiveDateTime.utc_now(), days_to_seconds(365), :seconds)
          },
          divisions: [
            %{
              id: UUID.generate(),
              name: "Бориспільське відділення Клініки Ноунейм",
              medical_service: "Послуга ПМД"
            }
          ]
        }
      ],
      nhs_legal_entity_id: UUID.generate(),
      nhs_signer_id: UUID.generate(),
      nhs_payment_method: "prepayment",
      nhs_payment_details: %{
        bank_name: "Банк номер 1",
        MFO: "351005",
        payer_account: "32009102701026"
      },
      nhs_signer_base: "на підставі наказу",
      issue_city: "Київ",
      price: Enum.random(100_000..200_000) |> to_float(),
      contract_number: "0000-9EAX-XT7X-3115",
      contract_request_id: UUID.generate(),
      is_active: true,
      is_suspended: false,
      inserted_by: UUID.generate(),
      updated_by: UUID.generate()
    }
  end

  defp to_float(number) when is_integer(number), do: number + 0.0
  defp days_to_seconds(count), do: 24 * 60 * 60 * count
end
