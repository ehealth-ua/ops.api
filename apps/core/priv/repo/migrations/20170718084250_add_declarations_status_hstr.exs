defmodule Core.Repo.Migrations.CreateDeclarationsStatusHstr do
  use Ecto.Migration

  def up do
    create table(:declarations_status_hstr) do
      add :declaration_id, :uuid, null: false
      add :status, :string, null: false
      timestamps(type: :utc_datetime, updated_at: false)
    end

    execute """
      CREATE OR REPLACE FUNCTION insert_declarations_status_hstr()
        RETURNS trigger AS
      $BODY$
      BEGIN
        INSERT INTO declarations_status_hstr(declaration_id,status,inserted_at)
        VALUES(NEW.id,NEW.status,now());

        RETURN NEW;
      END;
      $BODY$
      LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER on_declaration_insert
    AFTER INSERT
    ON declarations
    FOR EACH ROW
    EXECUTE PROCEDURE insert_declarations_status_hstr();
    """

    execute """
    CREATE TRIGGER on_declaration_update
    AFTER UPDATE
    ON declarations
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status)
    EXECUTE PROCEDURE insert_declarations_status_hstr();
    """
  end

  def down do
    execute("DROP TRIGGER IF EXISTS on_declaration_insert ON declarations;")
    execute("DROP TRIGGER IF EXISTS on_declaration_update ON declarations;")
    execute("DROP FUNCTION IF EXISTS insert_declarations_status_hstr();")

    drop table(:declarations_status_hstr)
  end
end
