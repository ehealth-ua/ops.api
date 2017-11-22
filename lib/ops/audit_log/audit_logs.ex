defmodule OPS.AuditLogs do
  @moduledoc false

  alias OPS.Repo
  import Ecto.Changeset

  alias EctoTrail.Changelog

  def create_audit_log(attrs \\ %{}) do
    %Changelog{}
    |> audit_log_changeset(attrs)
    |> Repo.insert()
  end

  def create_audit_logs(attrs_list \\ []) when is_list(attrs_list) do
    changes = Enum.map(attrs_list, &Map.put(&1, :inserted_at, NaiveDateTime.utc_now))

    Repo.insert_all(Changelog, changes, returning: true)
  end

  def audit_log_changeset(%Changelog{} = audit_log, attrs) do
    fields = ~W(
      actor_id
      resource
      resource_id
      changeset
    )a

    audit_log
    |> cast(attrs, fields)
    |> validate_required(fields)
  end
end
