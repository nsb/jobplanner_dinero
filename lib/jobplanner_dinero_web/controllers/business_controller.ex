defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller
  alias JobplannerDinero.Auth.Authorizer

  plug(JobplannerDineroWeb.Plugs.AuthenticateUser when action in [:index, :show])
  plug(:authorize_user when action in [:show])

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, _params) do
    redirect(conn, to: "/")
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
