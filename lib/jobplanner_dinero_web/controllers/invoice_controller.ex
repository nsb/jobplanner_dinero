defmodule JobplannerDineroWeb.InvoiceController do
  use JobplannerDineroWeb, :controller
  import Plug.Conn

  alias JobplannerDinero.Invoice

  def create(conn, %{"hook" => %{"event" => "invoice.added"}, "data" => data}) do
    case Invoice.create_invoice(data) do
      {:ok, _} -> text conn, "Ok"
      {:error, _} ->
        conn
        |> put_status(401)
        |> text("Error")
    end
  end
end
