defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller
  alias JobplannerDinero.Repo

  plug(JobplannerDineroWeb.Plugs.AuthenticateUser when action in [:index, :show])
  plug(:authorize_user when action in [:show])

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, _params) do
    redirect(conn, to: "/")
  end

  defp authorize_user(conn, _params) do
    %{params: %{"id" => business_id}, assigns: %{current_user: current_user}} = conn

    res =
      Repo.query(
        "select * from account_users_businesses where user_id = $1 and business_id = $2",
        [
          current_user.id,
          String.to_integer(business_id)
        ]
      )

    case res do
      {:ok, %{num_rows: 1}} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "You are not authorized to access that page")
        |> redirect(to: business_path(conn, :index))
        |> halt()
    end
  end
end
