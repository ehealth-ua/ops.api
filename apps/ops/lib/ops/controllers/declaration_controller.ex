defmodule OPS.Web.DeclarationController do
  @moduledoc false

  use OPS.Web, :controller

  alias Core.Declarations
  alias Core.Declarations.Declaration
  alias Scrivener.Page

  action_fallback(OPS.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- Declarations.list_declarations(params) do
      render(conn, "index.json", declarations: paging.entries, paging: paging)
    end
  end

  def create(conn, %{"declaration" => declaration_params}) do
    with {:ok, %Declaration{} = declaration} <- Declarations.create_declaration(declaration_params) do
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

    with {:ok, %Declaration{} = declaration} <- Declarations.update_declaration(declaration, declaration_params) do
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

      {:error, _transaction_step, changeset, _} ->
        {:error, changeset}
    end
  end

  def terminate_declaration(conn, %{"id" => id} = attrs) do
    with {:ok, %Declaration{} = declaration} <- Declarations.terminate_declaration(id, attrs) do
      render(conn, "show.json", declaration: declaration)
    end
  end

  def terminate_declarations(conn, attrs) do
    user_id = fetch_user_id(attrs)

    attrs =
      attrs
      |> Map.drop(["user_id"])
      |> Map.put("actor_id", user_id)

    with {:ok, terminated_declarations, _} <- Declarations.terminate_declarations(attrs) do
      render(conn, "terminated_declarations.json", declarations: terminated_declarations)
    end
  end

  def declarations_count(conn, params) do
    with {:ok, count} <- Declarations.count_by_employee_ids(params) do
      render(conn, "declarations_count.json", count: count)
    else
      :error -> {:error, {:"422", "missed \"ids\" parameter"}}
    end
  end

  def person_ids(conn, %{"employee_ids" => employee_ids}) do
    person_ids = Declarations.get_person_ids(employee_ids)

    render(conn, "person_ids.json", person_ids: person_ids)
  end

  def person_ids(_, _), do: {:error, {:"422", "missed \"employee_ids\" parameter"}}

  defp fetch_user_id(%{"user_id" => user_id}) when byte_size(user_id) > 0, do: user_id
  defp fetch_user_id(_), do: Confex.fetch_env!(:core, :system_user)
end
