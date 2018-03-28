defmodule OPS.Search do
  @moduledoc """
  Search implementation
  """

  defmacro __using__(_) do
    quote do
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
        statuses = changes |> Map.get(:status, "") |> String.split(",")
        start_year = changes |> Map.get(:start_year)
        params = changes |> Map.drop([:status, :start_year]) |> Map.to_list()

        query =
          from(
            e in entity,
            where: ^params,
            order_by: [desc: :inserted_at]
          )

        query
        |> add_query_statuses(statuses)
        |> add_query_start_year(start_year)
      end

      def get_search_query(entity, _changes), do: from(e in entity, order_by: [desc: :inserted_at])

      defp add_query_statuses(query, [""]), do: query
      defp add_query_statuses(query, statuses), do: where(query, [e], e.status in ^statuses)

      defp add_query_start_year(query, nil), do: query

      defp add_query_start_year(query, start_year),
        do: where(query, [d], fragment("date_part('year', ?) = ?", d.start_date, ^start_year))

      defoverridable get_search_query: 2
    end
  end
end
