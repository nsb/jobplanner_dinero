defmodule JobplannerDineroWeb.HealthControllerTest do
  use JobplannerDineroWeb.ConnCase

  test "GET /health/liveness", %{conn: conn} do
    conn = get conn, "/health/liveness"
    assert text_response(conn, 200) =~ "Ok"
  end
end
