defmodule JobplannerDineroWeb.InvoiceController do
  use JobplannerDineroWeb, :controller
  import Plug.Conn

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Invoice

  @dinero_api Application.get_env(:jobplanner_dinero, :dinero_api)
  @dinero_client_id System.get_env("DINERO_CLIENT_ID")
  @dinero_client_secret System.get_env("DINERO_CLIENT_SECRET")

  def create(conn, %{"hook" => %{"event" => "invoice.added"}, "data" => data}) do
    with {:ok, %{invoice: %{"client" => client}} = invoice} <- Invoice.create_invoice(data),
         invoice_with_business <- Repo.preload(invoice, :business),
         {:ok, %{"access_token" => access_token}} <-
           @dinero_api.authentication(
             @dinero_client_id,
             @dinero_client_secret,
             invoice_with_business.business.dinero_api_key
           ),
         {:ok, %{"Collection" => contacts}} when is_list(contacts) and length(contacts) >= 1 <-
           @dinero_api.get_contacts(invoice_with_business.business.dinero_id, access_token,
             queryFilter: "email eq #{client["email"]}"
           ),
         {:ok, _response} <-
           @dinero_api.create_invoice(
             invoice_with_business.business.dinero_id,
             access_token,
             Invoice.to_dinero_invoice(invoice, List.first(contacts) |> Map.get("contactGuid"))
           ) do
      json(conn, %{"message" => "Ok"})
    else
      {_, err} ->
        conn
        |> put_status(400)
        |> json(err)
    end
  end
end
