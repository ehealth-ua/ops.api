defmodule OPS.MedicationDispensesTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias OPS.MedicationDispense.Schema, as: MedicationDispense
  alias OPS.MedicationDispenses
  alias OPS.Repo

  test "terminate/1" do
    insert(:medication_dispense)
    assert 1 == count_by_status(MedicationDispense.status(:new))

    MedicationDispenses.terminate(0)
    assert 0 == count_by_status(MedicationDispense.status(:new))
    assert 1 == count_by_status(MedicationDispense.status(:expired))
  end

  defp count_by_status(status) do
    MedicationDispense
    |> where([md], md.status == ^status)
    |> select([md], count(md.id))
    |> Repo.one
  end
end
