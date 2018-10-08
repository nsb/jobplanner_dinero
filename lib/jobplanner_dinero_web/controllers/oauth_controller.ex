defmodule JobplannerDineroWeb.OauthController do
  use JobplannerDineroWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
