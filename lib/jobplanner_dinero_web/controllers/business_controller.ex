defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.User

  def index(conn, _params) do
    case conn.assigns[:current_user] do
      nil -> redirect(conn, to: "/auth/jobplanner")
      user_id ->
        user = Repo.get!(User, user_id) |> Repo.preload(:businesses)
        conn
        |> assign(:user, user)
        |> render("index.html")

    end
  end

  def show(conn, _params) do
    redirect(conn, to: "/")
  end
end
