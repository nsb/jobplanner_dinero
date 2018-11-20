defmodule JobplannerDineroWeb.BusinessControllerTest do
  use JobplannerDineroWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 302) =~ "<html><body>You are being <a href=\"/auth/jobplanner\">redirected</a>.</body></html>"
  end
end
