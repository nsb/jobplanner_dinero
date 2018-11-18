defmodule JobplannerDineroWeb.PageController do
  use JobplannerDineroWeb, :controller

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.User

  def index(conn, _params) do
    user_id =
      case conn.assigns[:current_user] do
        nil -> redirect(conn, to: "/auth/jobplanner")
        user_id -> user_id
      end

    user = Repo.get!(User, user_id) |> Repo.preload(:businesses)

    conn
    |> assign(:user, user)
    |> render("index.html")
  end

  def show(conn, _params) do
    redirect(conn, to: "/")
  end
end
