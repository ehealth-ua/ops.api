defmodule DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumerTest do
  @moduledoc false

  use Core.DataCase
  import Ecto.Query
  import Mox
  alias Core.Declarations.Declaration
  alias Core.Repo
  alias DeactivateDeclarationConsumer.Kafka.DeactivateDeclarationEventConsumer

  setup :verify_on_exit!

  describe "consume" do
    test "success consume person event" do
      expect(KafkaMock, :publish_to_event_manager, 205, fn _ -> :ok end)
      person_id = Ecto.UUID.generate()
      actor_id = Ecto.UUID.generate()
      reason = "some reason"
      reason_description = "some_reason_description"

      for _ <- 1..205, do: insert(:declaration, person_id: person_id)

      for _ <- 1..15, do: insert(:declaration)

      assert :ok ==
               DeactivateDeclarationEventConsumer.consume(%{
                 "person_id" => person_id,
                 "actor_id" => actor_id,
                 "reason" => reason,
                 "reason_description" => reason_description
               })

      employee_declarations =
        from(
          d in Declaration,
          where: d.person_id == ^person_id
        )
        |> Repo.all()

      other_declarations =
        from(
          d in Declaration,
          where: d.person_id != ^person_id
        )
        |> Repo.all()

      for employee_declaration <- employee_declarations do
        assert Declaration.status(:terminated) == employee_declaration.status
        assert reason == employee_declaration.reason
        assert reason_description == employee_declaration.reason_description
        assert actor_id == employee_declaration.updated_by
      end

      for other_declaration <- other_declarations do
        assert Declaration.status(:active) == other_declaration.status
        refute reason == other_declaration.reason
        refute reason_description == other_declaration.reason_description
        refute actor_id == other_declaration.updated_by
      end
    end

    test "success consume employee event" do
      expect(KafkaMock, :publish_to_event_manager, 205, fn _ -> :ok end)
      employee_id = Ecto.UUID.generate()
      actor_id = Ecto.UUID.generate()
      reason = "some reason"
      reason_description = "some_reason_description"

      for _ <- 1..205, do: insert(:declaration, employee_id: employee_id)

      for _ <- 1..15, do: insert(:declaration)

      assert :ok ==
               DeactivateDeclarationEventConsumer.consume(%{
                 "employee_id" => employee_id,
                 "actor_id" => actor_id,
                 "reason" => reason,
                 "reason_description" => reason_description
               })

      employee_declarations =
        from(
          d in Declaration,
          where: d.employee_id == ^employee_id
        )
        |> Repo.all()

      other_declarations =
        from(
          d in Declaration,
          where: d.employee_id != ^employee_id
        )
        |> Repo.all()

      for employee_declaration <- employee_declarations do
        assert Declaration.status(:terminated) == employee_declaration.status
        assert reason == employee_declaration.reason
        assert reason_description == employee_declaration.reason_description
        assert actor_id == employee_declaration.updated_by
      end

      for other_declaration <- other_declarations do
        assert Declaration.status(:active) == other_declaration.status
        refute reason == other_declaration.reason
        refute reason_description == other_declaration.reason_description
        refute actor_id == other_declaration.updated_by
      end
    end

    test "success consume event when there are no active/pending declarations found" do
      employee_id = Ecto.UUID.generate()
      actor_id = Ecto.UUID.generate()
      reason = "some reason"
      reason_description = "some_reason_description"

      assert :ok ==
               DeactivateDeclarationEventConsumer.consume(%{
                 "employee_id" => employee_id,
                 "actor_id" => actor_id,
                 "reason" => reason,
                 "reason_description" => reason_description
               })
    end
  end
end
