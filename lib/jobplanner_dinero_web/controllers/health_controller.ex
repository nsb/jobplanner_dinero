defmodule JobplannerDineroWeb.HealthController do
  use JobplannerDineroWeb, :controller

  action_fallback(JobplannerDineroWeb.FallbackController)

  def index(conn, _params) do
    JobplannerDinero.Repo.query!("SELECT NULL;")
    text(conn, "Ok")
  end
end
