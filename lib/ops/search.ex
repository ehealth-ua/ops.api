defmodule OPS.Search do
  @moduledoc """
  Search implementation
  """

  defmacro __using__(_) do
    quote  do
      import Ecto.{Query, Changeset}, warn: false
      import OPS.Search

      alias OPS.Repo

      def search(%Ecto.Changeset{valid?: true, changes: changes}, search_params, entity) do
        entity
        |> get_search_query(changes)
        |> Repo.paginate(search_params)
      end

      def search(%Ecto.Changeset{valid?: false} = changeset, _search_params, _entity) do
        {:error, changeset}
      end

      def get_search_query(entity, changes) when map_size(changes) > 0 do
        statuses =
          changes
          |> Map.get(:status, "")
          |> String.split(",")

        params =
          changes
          |> Map.drop([:status])
          |> Map.to_list()

        query =
          from e in entity,
            where: ^params,
            order_by: [desc: :inserted_at]
        add_status_where(query, statuses)
      end
      def get_search_query(entity, _changes), do: from e in entity, order_by: [desc: :inserted_at]

      defp add_status_where(query, [""]), do: query
      defp add_status_where(query, statuses), do: query |> where([e], e.status in ^statuses)

      defoverridable [get_search_query: 2]
    end
  end

  def to_integer(value) when is_binary(value), do: String.to_integer(value)
  def to_integer(value), do: value
end
