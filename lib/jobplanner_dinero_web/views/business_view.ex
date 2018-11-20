defmodule JobplannerDineroWeb.BusinessView do
  use JobplannerDineroWeb, :view

  def businesses(conn) do
    conn.assigns[:current_user].businesses
  end
end
