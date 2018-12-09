defmodule JobplannerDineroWeb.InvoiceController do
  use JobplannerDineroWeb, :controller
  import Plug.Conn

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Invoice
  alias JobplannerDinero.Account.Business

  @dinero_api Application.get_env(:jobplanner_dinero, :dinero_api)

  def create(conn, %{"hook" => %{"event" => "invoice.added"}, "data" => data}) do
    case Invoice.create_invoice(data) do
      {:ok, invoice} ->
        invoice_with_business =
          invoice
          |> Repo.preload(:business)

        business = invoice_with_business.business

        client_id = System.get_env("DINERO_CLIENT_ID")

        client_secret = System.get_env("DINERO_CLIENT_SECRET")

        with {:ok, %{"access_token" => access_token}} <-
               @dinero_api.authentication(client_id, client_secret, business.dinero_api_key),
             {:ok, response} <-
               @dinero_api.get_contacts(business.dinero_id, access_token,
                 queryFilter: "email equals niels.busch@gmail.com"
               ) do
          IO.inspect(response)
          text(conn, "Ok")
        else
          _err ->
            conn
            |> put_status(401)
            |> text("Error")
        end
    end
  end
end
