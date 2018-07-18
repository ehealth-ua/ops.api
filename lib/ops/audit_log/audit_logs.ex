defmodule OPS.AuditLogs do
  @moduledoc false

  use Confex, otp_app: :ops
  import Ecto.Changeset

  alias EctoTrail.Changelog
  alias OPS.Repo

  def create_audit_log(attrs \\ %{}) do
    %Changelog{}
    |> audit_log_changeset(attrs)
    |> Repo.insert()
  end

  def create_audit_logs(attrs_list \\ []) when is_list(attrs_list) do
    attrs_list
    |> Enum.map(&Map.put(&1, :inserted_at, DateTime.utc_now()))
    |> insert_chunk_records
  end

  @doc """
  Insert n of records m times, because postgres ecto has limit of parameters
  """
  def insert_chunk_records([]), do: {:ok, nil}

  def insert_chunk_records(changes) do
    chunk_limit = config()[:max_audit_record_insert]
    {records, rest} = Enum.split(changes, chunk_limit)
    Repo.insert_all(Changelog, records)
    insert_chunk_records(rest)
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
