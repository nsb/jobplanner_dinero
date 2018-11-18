defmodule JobplannerDineroWeb.PageView do
  use JobplannerDineroWeb, :view

  def businesses(conn) do
    conn.assigns[:user].businesses
  end
end
