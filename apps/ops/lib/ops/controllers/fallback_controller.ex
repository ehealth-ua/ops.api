defmodule OPS.Web.FallbackController do
  @moduledoc """
  This controller should be used as `action_fallback` in rest of controllers to remove duplicated error handling.
  """
  use OPS.Web, :controller

  def call(conn, {:error, :access_denied}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(EView.Views.Error)
    |> render(:"401")
  end

  def call(conn, {:error, {:conflict, error}}) do
    conn
    |> put_status(:conflict)
    |> put_view(EView.Views.Error)
    |> render(:"409", %{message: error})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(EView.Views.Error)
    |> render(:"404")
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> put_view(EView.Views.Error)
    |> render(:"404")
  end

  def call(conn, {:error, {:"422", error}}) do
    conn
    |> put_status(422)
    |> put_view(EView.Views.Error)
    |> render(:"400", %{message: error})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EView.Views.ValidationError)
    |> render(:"422", changeset)
  end

  def call(conn, %Ecto.Changeset{valid?: false} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(EView.Views.ValidationError)
    |> render(:"422", changeset)
  end
end
