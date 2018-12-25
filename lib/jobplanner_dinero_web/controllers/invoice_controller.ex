defmodule JobplannerDineroWeb.InvoiceController do
  use JobplannerDineroWeb, :controller
  import Plug.Conn

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Invoice

  @dinero_api Application.get_env(:jobplanner_dinero, :dinero_api)
  @dinero_client_id System.get_env("DINERO_CLIENT_ID")
  @dinero_client_secret System.get_env("DINERO_CLIENT_SECRET")

  def create(conn, %{"hook" => %{"event" => "invoice.added"}, "data" => data}) do
    with {:ok,
          %{invoice: %{"client" => _client, "property" => _property} = webhook_data} = invoice} <-
           Invoice.create_invoice(data),
         invoice_with_business <- Repo.preload(invoice, :business),
         {:ok, %{"access_token" => access_token}} <-
           @dinero_api.authentication(
             @dinero_client_id,
             @dinero_client_secret,
             invoice_with_business.business.dinero_api_key
           ),
         #  {:ok, %{"Collection" => contacts}} when is_list(contacts) and length(contacts) >= 1 <-
         #    @dinero_api.get_contacts(invoice_with_business.business.dinero_id, access_token,
         #      queryFilter: "email eq #{client["email"]}"
         #    ),
         {:ok, contact} <-
           get_or_create_contact(
             invoice_with_business.business.dinero_id,
             access_token,
             webhook_data
           ),
         {:ok, _response} <-
           @dinero_api.create_invoice(
             invoice_with_business.business.dinero_id,
             access_token,
             Invoice.to_dinero_invoice(invoice, contact |> Map.get("ContactGuid") || contact |> Map.get("contactGuid"))
           ) do
      json(conn, %{"message" => "Ok"})
    else
      {_, err} ->
        conn
        |> put_status(400)
        |> json(err)
    end
  end

  defp get_or_create_contact(
         dinero_id,
         access_token,
         %{"client" => client, "property" => property} = _invoice
       ) do
    case @dinero_api.get_contacts(dinero_id, access_token,
           queryFilter: "Email eq '#{client["email"]}'"
         ) do
      {:ok, %{"Collection" => contacts}} when is_list(contacts) and length(contacts) >= 1 ->
        {:ok, Enum.at(contacts, 0)}

      _ ->
        @dinero_api.create_contact(
          dinero_id,
          access_token,
          jobplanner_client_to_dinero_contact(client, property)
        )
    end
  end

  defp jobplanner_client_to_dinero_contact(client, property) do
    %Dinero.DineroContact{
      Name: "#{client["first_name"]} #{client["last_name"]}",
      Street: property["address1"],
      ZipCode: property["zip_code"],
      City: property["city"],
      # TODO FIXME
      CountryKey:
        if String.length(property["country"]) > 0 do
          String.upcase(property["country"])
        else
          "DK"
        end,
      Email: client["email"],
      # TODO FIXME
      isPerson: true
    }
  end
end
