defmodule OPS.Web.DeclarationController do
  @moduledoc false

  use OPS.Web, :controller

  alias Scrivener.Page
  alias OPS.Declarations
  alias OPS.Declarations.Declaration

  action_fallback OPS.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- Declarations.list_declarations(params) do
      render(conn, "index.json", declarations: paging.entries, paging: paging)
    end
  end

  def create(conn, %{"declaration" => declaration_params}) do
    result = Declarations.create_declaration(declaration_params)

    with {:ok, %Declaration{} = declaration} <- result do
      conn
      |> put_status(:created)
      |> put_resp_header("location", declaration_path(conn, :show, declaration))
      |> render("show.json", declaration: declaration)
    end
  end

  def show(conn, %{"id" => id}) do
    declaration = Declarations.get_declaration!(id)
    render(conn, "show.json", declaration: declaration)
  end

  def update(conn, %{"id" => id, "declaration" => declaration_params}) do
    declaration = Declarations.get_declaration!(id)
    result = Declarations.update_declaration(declaration, declaration_params)
    with {:ok, %Declaration{} = declaration} <- result do
      render(conn, "show.json", declaration: declaration)
    end
  end

  def delete(conn, %{"id" => id}) do
    declaration = Declarations.get_declaration!(id)
    with {:ok, %Declaration{}} <- Declarations.delete_declaration(declaration) do
      send_resp(conn, :no_content, "")
    end
  end

  def create_with_termination_logic(conn, declaration_params) do
    case Declarations.create_declaration_with_termination_logic(declaration_params) do
      {:ok, %{new_declaration: declaration}} ->
        render(conn, "show.json", declaration: declaration)
      {:error, _transaction_step, changeset, _} -> {:error, changeset}
    end
  end

  def terminate_declarations(conn, %{"user_id" => user_id, "id" => employee_id}) do
    with {:ok, result} <- Declarations.terminate_declarations(user_id, employee_id) do
      render(conn, "terminated_declarations.json", declarations: result.logged_terminations)
    end
  end

  def terminate_person_declarations(conn, %{"id" => person_id}) do
    user_id = Confex.get_env(:ops, :declaration_terminator_user)

    with {:ok, result} <- Declarations.terminate_person_declarations(user_id, person_id) do
      render(conn, "terminated_declarations.json", declarations: result.logged_terminations)
    end
  end
end
