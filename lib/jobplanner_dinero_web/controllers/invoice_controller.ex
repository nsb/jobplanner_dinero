defmodule JobplannerDineroWeb.InvoiceController do
  use JobplannerDineroWeb, :controller
  import Plug.Conn
  require Logger

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Invoice

  @dinero_api Application.get_env(:jobplanner_dinero, :dinero_api)
  @dinero_client_id System.get_env("DINERO_CLIENT_ID")
  @dinero_client_secret System.get_env("DINERO_CLIENT_SECRET")

  def create(conn, %{"hook" => %{"event" => "invoice.added"}, "data" => data}) do
    # save invoice to database
    with {:ok,
          %{invoice: %{"client" => _client} = invoice} = webhook_data} <-
           Invoice.create_invoice(data),

         # load related business
         invoice_with_business <- Repo.preload(webhook_data, :business),

         # get access token from Dinero
         {:ok, %{"access_token" => access_token}} <-
           @dinero_api.authentication(
             @dinero_client_id,
             @dinero_client_secret,
             invoice_with_business.business.dinero_api_key
           ),

         # get or create Dinero contact
         {:ok, contact} <-
           get_or_create_contact(
             invoice_with_business.business.dinero_id,
             access_token,
             invoice
           ),

         # create the invoice in Dinero
         {:ok, %{"Guid" => invoice_guid}} <-
           @dinero_api.create_invoice(
             invoice_with_business.business.dinero_id,
             access_token,
             Invoice.to_dinero_invoice(
               webhook_data,
               contact |> Map.get("ContactGuid") || contact |> Map.get("contactGuid")
             )
           ) do
      synced = DateTime.utc_now()

      Invoice.changeset(invoice_with_business, %{dinero_id: invoice_guid, synced: synced})
      |> Repo.update()

      json(conn, %{
        "message" => "Ok",
        "id" => invoice_with_business.id,
        "guid" => invoice_guid,
        "created" => synced
      })
    else
      {_, err} ->
        Logger.error(inspect(err))

        conn
        |> put_status(400)
        |> json(err)
    end
  end

  defp get_or_create_contact(
         dinero_id,
         access_token,
         %{"client" => client} = _invoice
       ) do
    queries = [
      "ExternalReference eq 'myjobplanner:#{client["id"]}'",
      "Email eq '#{client["email"]}'"
    ]

    case Enum.find_value(queries, nil, fn query ->
           case @dinero_api.get_contacts(dinero_id, access_token, queryFilter: query) do
             {:ok, %{"Collection" => contacts}}
             when is_list(contacts) and length(contacts) >= 1 ->
               {:ok, Enum.at(contacts, 0)}

             _ ->
               nil
           end
         end) do
      {:ok, contact} ->
        {:ok, contact}

      _ ->
        @dinero_api.create_contact(
          dinero_id,
          access_token,
          jobplanner_client_to_dinero_contact(client)
        )
    end
  end

  defp jobplanner_client_to_dinero_contact(client) do
    %Dinero.DineroContact{
      ExternalReference: "myjobplanner:#{client["id"]}",
      Name: (if client["is_business"], do: client["business_name"], else: "#{client["first_name"]} #{client["last_name"]}"),
      Street: (if client["address_use_property"], do: client["properties"][0]["address1"], else: client["address1"]),
      ZipCode: (if client["address_use_property"], do: client["properties"][0]["zip_code"], else: client["zip_code"]),
      City: (if client["address_use_property"], do: client["properties"][0]["city"], else: client["city"]),
      # TODO FIXME
      CountryKey: "DK",
      Email: client["email"],
      Phone: client["phone"],
      isPerson: !client["is_business"]
    }
  end
end
