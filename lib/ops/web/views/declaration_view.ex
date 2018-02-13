defmodule OPS.Web.DeclarationView do
  @moduledoc false

  use OPS.Web, :view

  alias OPS.Web.DeclarationView

  @fields_declaration_in_list ~w(
    id
    person_id
    employee_id
    division_id
    legal_entity_id
    scope
    start_date
    end_date
    signed_at
    status
    declaration_request_id
    reason
    reason_description
    inserted_at
    created_by
    updated_at
    updated_by
    is_active
  )a

  @fields_termination_declaration ~w(id status reason reason_description updated_by updated_at)a

  def render("index.json", %{declarations: declarations}) do
    render_many(declarations, DeclarationView, "declaration_in_list.json")
  end

  def render("show.json", %{declaration: declaration}) do
    render_one(declaration, DeclarationView, "declaration_in_list.json")
  end

  def render("declaration_in_list.json", %{declaration: declaration}) do
    Map.take(declaration, @fields_declaration_in_list)
  end

  def render("terminated_declarations.json", %{declarations: declarations}) do
    %{terminated_declarations: Enum.map(declarations, &sanitize/1)}
  end

  defp sanitize(%OPS.Declarations.Declaration{} = declaration) do
    Map.take(declaration, @fields_termination_declaration)
  end
end
