defmodule JobplannerDineroWeb.InvoiceControllerTest do
  use JobplannerDineroWeb.ConnCase

  import Mox
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.Business

  setup do
    business = %Business{name: "idealrent", jobplanner_id: 1, dinero_id: 1} |> Repo.insert!()

    webhook_data = %{
      "hook" => %{
        "id" => 1,
        "event" => "invoice.added",
        "target" => "https://example.com/abc"
      },
      "data" => %{
        "id" => 1,
        "created" => "2018-11-24T15:41:41.178860Z",
        "business" => business.id,
        "client" => %{
          "id" => 1363,
          "business" => 1,
          "first_name" => "Donald",
          "last_name" => "Trump",
          "email" => "trump@example.com",
          "phone" => "1223412342",
          "notes" => "",
          "properties" => [
            %{
              "id" => 1,
              "address1" => "White House",
              "address2" => "",
              "city" => "Washington",
              "zip_code" => "1342",
              "country" => ""
            }
          ],
          "upcoming_visit_reminder_email_enabled" => false,
          "external_id" => "",
          "imported_from" => "",
          "imported_via" => ""
        },
        "job" => 270,
        "description" => "",
        "date" => "2018-11-24",
        "visits" => [
          %{
            "id" => 77417,
            "business" => 1,
            "job" => 270,
            "completed" => true,
            "begins" => "2018-11-24T23:00:00Z",
            "ends" => "2018-11-24T23:00:00Z",
            "anytime" => true,
            "line_items" => [
              %{
                "id" => 80331,
                "name" => "Standard rengøring",
                "description" =>
                  "støvsugning (inkl. møbler og altan), gulvvask, støve af, rengøring af køkken, badeværelse, toilet og døre",
                "quantity" => 1,
                "unit_cost" => "432.00",
                "total_cost" => "432.00"
              }
            ]
          }
        ],
        "property" => %{
          "id" => 1,
          "address1" => "White House",
          "address2" => "",
          "city" => "Washington",
          "zip_code" => "1342",
          "country" => ""
        },
        "paid" => false
      }
    }

    contacts_response = %{
      "Collection" => [
        %{
          "ContactGuid" => "a5f62248-ae7c-4a04-b83d-aa34f0e62ce3",
          "CreatedAt" => "2018-12-08T18:52:45.9706751+00:00",
          "UpdatedAt" => "2018-12-08T18:52:45.9706751+00:00",
          "DeletedAt" => "2018-12-08T18:52:45.9706751+00:00",
          "IsDebitor" => true,
          "IsCreditor" => true,
          "ExternalReference" => "Fx. WebShopID:42",
          "Name" => "John Doe",
          "Street" => "Main road 42",
          "ZipCode" => "2100",
          "City" => "Copenhagen",
          "CountryKey" => "DK",
          "Phone" => "+45 99 99 99 99",
          "Email" => "test@test.com",
          "Webpage" => "test.com",
          "AttPerson" => "Donald Duck",
          "VatNumber" => "12345674",
          "EanNumber" => "1111000022223",
          "PaymentConditionType" => "Netto",
          "PaymentConditionNumberOfDays" => 8,
          "IsPerson" => false
        },
        %{
          "ContactGuid" => "a5f62248-ae7c-4a04-b83d-aa34f0e62ce3",
          "CreatedAt" => "2018-12-08T18:52:45.9706751+00:00",
          "UpdatedAt" => "2018-12-08T18:52:45.9706751+00:00",
          "DeletedAt" => "2018-12-08T18 =>52:45.9706751+00:00",
          "IsDebitor" => true,
          "IsCreditor" => true,
          "ExternalReference" => "Fx. WebShopID:42",
          "Name" => "John Doe",
          "Street" => "Main road 42",
          "ZipCode" => "2100",
          "City" => "Copenhagen",
          "CountryKey" => "DK",
          "Phone" => "+45 99 99 99 99",
          "Email" => "test@test.com",
          "Webpage" => "test.com",
          "AttPerson" => "Donald Duck",
          "VatNumber" => "12345674",
          "EanNumber" => "1111000022223",
          "PaymentConditionType" => "Netto",
          "PaymentConditionNumberOfDays" => 8,
          "IsPerson" => false
        }
      ],
      "Pagination" => %{
        "MaxPageSizeAllowed" => 0,
        "PageSize" => 0,
        "Result" => 0,
        "ResultWithoutFilter" => 0,
        "Page" => 0
      }
    }

    %{webhook_data: webhook_data, contacts_response: contacts_response, business: business}
  end

  test "CREATE /webhooks/invoice", %{
    conn: conn,
    webhook_data: webhook_data,
    contacts_response: contacts_response
  } do
    expect(JobplannerDineroWeb.DineroApiMock, :authentication, fn _, _, _ ->
      {:ok, %{"access_token" => "abc"}}
    end)

    expect(JobplannerDineroWeb.DineroApiMock, :get_contacts, fn _, _, _ ->
      {:ok, contacts_response}
    end)

    expect(JobplannerDineroWeb.DineroApiMock, :create_invoice, fn _, _, _, _ ->
      {:ok, nil}
    end)

    conn = post(conn, "/webhooks/invoice", webhook_data)
    assert text_response(conn, 200) =~ "Ok"
  end
end
