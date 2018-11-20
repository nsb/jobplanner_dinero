defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller

  plug JobplannerDineroWeb.Plugs.AuthenticateUser when action in [:index, :new, :create, :show, :edit, :update, :delete]

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, _params) do
    redirect(conn, to: "/")
  end

end
