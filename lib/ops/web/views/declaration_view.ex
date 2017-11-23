defmodule OPS.Web.DeclarationView do
  @moduledoc false

  use OPS.Web, :view

  alias OPS.Web.DeclarationView

  def render("index.json", %{declarations: declarations}) do
    render_many(declarations, DeclarationView, "declaration_in_list.json")
  end

  def render("show.json", %{declaration: declaration}) do
    render_one(declaration, DeclarationView, "declaration_in_list.json")
  end

  def render("declaration_in_list.json", %{declaration: declaration}) do
    %{
       id: declaration.id,
       person_id: declaration.person_id,
       employee_id: declaration.employee_id,
       division_id: declaration.division_id,
       legal_entity_id: declaration.legal_entity_id,
       scope: declaration.scope,
       start_date: declaration.start_date,
       end_date: declaration.end_date,
       signed_at: declaration.signed_at,
       status: declaration.status,
       declaration_request_id: declaration.declaration_request_id,
       inserted_at: declaration.inserted_at,
       created_by: declaration.created_by,
       updated_at: declaration.updated_at,
       updated_by: declaration.updated_by,
       is_active: declaration.is_active
    }
  end

  def render("terminated_declarations.json", %{declarations: declarations}) do
    %{terminated_declarations: Enum.map(declarations, &sanitize/1)}
  end

  defp sanitize(%OPS.Declarations.Declaration{} = declaration) do
    declaration
    |> Map.from_struct()
    |> Enum.reduce(%{}, fn ({k, v}, acc) ->
         if k != :__meta__ and v != nil, do: Map.put(acc, k, v), else: acc
      end)
  end
end
