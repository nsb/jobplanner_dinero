defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller
  alias JobplannerDinero.Repo
  alias JobplannerDineroWeb.JobplannerOAuth2
  alias JobplannerDinero.Auth.Authorizer
  alias JobplannerDinero.Account.User
  alias JobplannerDinero.Account.Business

  plug(JobplannerDineroWeb.Plugs.AuthenticateUser when action in [:index, :show])
  plug(:authorize_user when action in [:show, :edit, :update])

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    case business.dinero_api_key do
      nil ->
        redirect(conn, to: business_path(conn, :edit, business))

      _ ->
        changeset = Business.change_business(business)
        render(conn, "show.html", business: business, changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))
    changeset = Business.change_business(business)
    render(conn, "edit.html", business: business, changeset: changeset)
  end

  def update(conn, %{"id" => id, "business" => business_params}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    business
    |> Business.changeset(business_params)
    |> Repo.update()
    |> case do
      {:ok, business} ->
        conn
        |> put_flash(:info, "Business updated sucessfully.")
        |> redirect(to: business_path(conn, :show, business))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", business: business, changeset: changeset)
    end
  end

  def activate(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    client = JobplannerOAuth2.client(conn.assigns.current_user.jobplanner_access_token)

    Business.delete_invoice_webhook(client, business)

    case client
         |> OAuth2.Client.put_header("Content-Type", "application/json")
         |> Business.create_invoice_webhook(business) do
      {:ok, business} ->
        conn
        |> put_flash(:info, "Activated Dinero integration successfully")
        |> redirect(to: business_path(conn, :show, business))
        |> halt()

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not activate webhook")
        |> redirect(to: business_path(conn, :show, business))
        |> halt()
    end
  end

  def deactivate(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    client = JobplannerOAuth2.client(conn.assigns.current_user.jobplanner_access_token)

    case Business.delete_invoice_webhook(client, business) do
      {:ok, business} ->
        conn
        |> put_flash(:info, "Deactivated Dinero integration successfully")
        |> redirect(to: business_path(conn, :show, business))
        |> halt()

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not deactivate Dinero integration")
        |> redirect(to: business_path(conn, :show, business))
        |> halt()
    end
  end

  defp authorize_user(conn, _params) do
    %{params: %{"id" => business_id}} = conn

    if Authorizer.can_manage?(conn.assigns.current_user, String.to_integer(business_id)) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access that page")
      |> redirect(to: business_path(conn, :index))
      |> halt()
    end
  end
end
