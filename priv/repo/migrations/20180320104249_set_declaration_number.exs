defmodule OPS.Repo.Migrations.SetDeclarationNumber do
  @moduledoc false

  alias OPS.Repo
  alias OPS.Declarations.Declaration
  use Ecto.Migration
  import Ecto.Query
  import Ecto.Changeset

  @human_readble_symbols ~w(0 1 2 3 4 5 6 7 8 9 A E H K M P T X)
  @ver_1 "0000-"

  def change do
    set_declaration_number()

    alter table(:declarations) do
      modify(:declaration_number, :string, null: false)
    end

    create(unique_index(:declarations, [:declaration_number]))
  end

  defp set_declaration_number do
    query =
      Declaration
      |> where([d], is_nil(d.declaration_number))
      |> limit(1000)

    declarations =
      query
      |> Repo.all()
      |> Enum.map(fn declaration ->
        declaration
        |> cast(%{"declaration_number" => generate(1, 2)}, ~w(declaration_number)a)
        |> Repo.update()
      end)

    if !Enum.empty?(declarations), do: set_declaration_number()
  end

  def generate(version, blocks \\ 3) do
    do_generate(version, blocks)
  end

  defp do_generate(1, blocks) do
    sequence =
      1..blocks
      |> Enum.map(fn _ -> get_combination_of(4) end)
      |> Enum.join("-")

    @ver_1 <> sequence
  end

  defp get_combination_of(number_length) do
    1..number_length
    |> Enum.map(fn _ -> Enum.random(@human_readble_symbols) end)
    |> Enum.join()
  end
end
