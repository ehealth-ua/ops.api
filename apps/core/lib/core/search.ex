defmodule Core.Search do
  @moduledoc """
  Search implementation
  """

  defmacro __using__(_) do
    quote do
      import Core.Search
      import Ecto.Query
      import Ecto.Changeset

      alias Core.Declarations.Declaration

      @read_repo Application.get_env(:core, :repos)[:read_repo]

      def search(%Ecto.Changeset{valid?: true, changes: changes}, search_params, entity) do
        entity
        |> get_search_query(changes)
        |> @read_repo.paginate(search_params)
      end

      def search(%Ecto.Changeset{valid?: false} = changeset, _search_params, _entity) do
        {:error, changeset}
      end

      def get_search_query(entity, changes) do
        entity
        |> get_query_condition(changes)
        |> order_by([e], desc: :inserted_at)
      end

      def get_count_query(entity, changes) do
        entity |> get_query_condition(changes) |> select([d], count(d.id))
      end

      def get_query_condition(entity, changes) when map_size(changes) > 0 do
        statuses = changes |> Map.get(:status, "") |> String.split(",")
        start_year = changes |> Map.get(:start_year)
        params = changes |> Map.drop([:status, :start_year]) |> Map.to_list()

        entity
        |> where([e], ^params)
        |> add_query_statuses(statuses)
        |> add_query_start_year(start_year)
      end

      def get_query_condition(entity, _changes), do: entity

      defp add_query_statuses(query, [""]), do: query
      defp add_query_statuses(query, statuses), do: where(query, [e], e.status in ^statuses)

      defp add_query_start_year(query, nil), do: query

      defp add_query_start_year(query, start_year),
        do: where(query, [d], fragment("date_part('year', ?) = ?", d.start_date, ^start_year))

      defoverridable get_search_query: 2
    end
  end
end
