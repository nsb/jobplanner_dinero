defmodule JobplannerDineroWeb.Plugs.AuthenticateUser do
  import Plug.Conn
  import Phoenix.Controller

  def init(_params) do
  end

  def call(conn, _params) do
    if conn.assigns.user_signed_in? do
      conn
    else
      conn
      |> redirect(to: "/auth/jobplanner")
      |> halt()
    end
  end
end
