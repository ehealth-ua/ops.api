defmodule DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumerTest do
  @moduledoc false

  use Core.DataCase
  alias Core.Declarations
  alias Core.Declarations.Declaration
  alias DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumer

  describe "consume" do
    test "success consume person event" do
      person_id = Ecto.UUID.generate()
      actor_id = Ecto.UUID.generate()
      reason = "some reason"
      reason_description = "some_reason_description"

      declaration1 = insert(:declaration, person_id: person_id)
      declaration2 = insert(:declaration, person_id: person_id)
      declaration3 = insert(:declaration, person_id: Ecto.UUID.generate())

      assert Declaration.status(:active) == declaration1.status
      assert Declaration.status(:active) == declaration2.status
      assert Declaration.status(:active) == declaration3.status

      refute actor_id == declaration1.updated_by
      refute actor_id == declaration2.updated_by
      refute actor_id == declaration3.updated_by

      assert :ok ==
               DeactivateDeclarationEventConsumer.consume(%{
                 "person_id" => person_id,
                 "actor_id" => actor_id,
                 "reason" => reason,
                 "reason_description" => reason_description
               })

      declaration1 = Declarations.get_declaration!(declaration1.id)
      declaration2 = Declarations.get_declaration!(declaration2.id)
      declaration3 = Declarations.get_declaration!(declaration3.id)

      assert Declaration.status(:terminated) == declaration1.status
      assert Declaration.status(:terminated) == declaration2.status
      assert Declaration.status(:active) == declaration3.status

      assert actor_id == declaration1.updated_by
      assert actor_id == declaration2.updated_by
      refute actor_id == declaration3.updated_by

      assert reason == declaration1.reason
      assert reason == declaration2.reason
      refute reason == declaration3.reason

      assert reason_description == declaration1.reason_description
      assert reason_description == declaration2.reason_description
      refute reason_description == declaration3.reason_description
    end

    test "success consume employee event" do
      employee_id = Ecto.UUID.generate()
      actor_id = Ecto.UUID.generate()
      reason = "some reason"
      reason_description = "some_reason_description"

      declaration1 = insert(:declaration, employee_id: employee_id)
      declaration2 = insert(:declaration, employee_id: employee_id)
      declaration3 = insert(:declaration, employee_id: Ecto.UUID.generate())

      assert Declaration.status(:active) == declaration1.status
      assert Declaration.status(:active) == declaration2.status
      assert Declaration.status(:active) == declaration3.status

      refute actor_id == declaration1.updated_by
      refute actor_id == declaration2.updated_by
      refute actor_id == declaration3.updated_by

      assert :ok ==
               DeactivateDeclarationEventConsumer.consume(%{
                 "employee_id" => employee_id,
                 "actor_id" => actor_id,
                 "reason" => reason,
                 "reason_description" => reason_description
               })

      declaration1 = Declarations.get_declaration!(declaration1.id)
      declaration2 = Declarations.get_declaration!(declaration2.id)
      declaration3 = Declarations.get_declaration!(declaration3.id)

      assert Declaration.status(:terminated) == declaration1.status
      assert Declaration.status(:terminated) == declaration2.status
      assert Declaration.status(:active) == declaration3.status

      assert actor_id == declaration1.updated_by
      assert actor_id == declaration2.updated_by
      refute actor_id == declaration3.updated_by

      assert reason == declaration1.reason
      assert reason == declaration2.reason
      refute reason == declaration3.reason

      assert reason_description == declaration1.reason_description
      assert reason_description == declaration2.reason_description
      refute reason_description == declaration3.reason_description
    end
  end
end
