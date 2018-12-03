defmodule Core.MedicationDispensesTest do
  @moduledoc false

  use Core.DataCase

  alias Core.MedicationDispenseStatusHistory
  alias Core.Repo

  test "status history" do
    assert 0 == count_history()
    medication_dispense = insert(:medication_dispense)
    assert 1 == count_history()

    medication_dispense_history =
      MedicationDispenseStatusHistory
      |> Repo.all()
      |> hd()

    assert %{status: "NEW"} = medication_dispense_history

    medication_dispense
    |> cast(%{status: "REJECTED"}, ~w(status)a)
    |> Repo.update!()

    assert 2 == count_history()

    medication_dispense_history =
      MedicationDispenseStatusHistory
      |> Repo.all()
      |> List.last()

    assert %{status: "REJECTED"} = medication_dispense_history
  end

  defp count_history do
    MedicationDispenseStatusHistory
    |> select([mdh], count(mdh.id))
    |> Repo.one()
  end
end
