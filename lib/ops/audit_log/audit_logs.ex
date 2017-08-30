defmodule OPS.AuditLogs do
  @moduledoc false

  alias OPS.Repo
  import Ecto.Changeset

  alias EctoTrail.Changelog

  def create_audit_log(attrs \\ %{}) do
    %Changelog{}
    |> audit_log_changeset(attrs)
    |> Repo.insert
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
