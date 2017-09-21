defmodule OPS.Repo.Migrations.CreateMedicationDispenseHistory do
  use Ecto.Migration

  def up do
    create table(:medication_dispense_status_hstr) do
      add :medication_dispense_id, :uuid, null: false
      add :status, :string, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    execute """
    CREATE OR REPLACE FUNCTION insert_medication_dispense_status_hstr()
    RETURNS trigger AS
    $BODY$
    BEGIN
    INSERT INTO medication_dispense_status_hstr(medication_dispense_id,status,inserted_at)
    VALUES(NEW.id,NEW.status,now());

    RETURN NEW;
    END;
    $BODY$
    LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER on_medication_dispense_insert
    AFTER INSERT
    ON medication_dispenses
    FOR EACH ROW
    EXECUTE PROCEDURE insert_medication_dispense_status_hstr();
    """

    execute """
    CREATE TRIGGER on_medication_dispense_update
    AFTER UPDATE
    ON medication_dispenses
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE PROCEDURE insert_medication_dispense_status_hstr();
    """
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_medication_dispense_insert ON medication_dispenses;")
    execute("DROP TRIGGER IF EXISTS on_medication_dispense_update ON medication_dispenses;")
    execute("DROP FUNCTION IF EXISTS insert_medication_dispense_status_hstr();")

    drop table(:medication_dispense_status_hstr)
  end
end
