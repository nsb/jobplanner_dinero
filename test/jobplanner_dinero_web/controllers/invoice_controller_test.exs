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
          "contactGuid" => "a5f62248-ae7c-4a04-b83d-aa34f0e62ce3",
          "name" => "Donald Trump"
        }
      ],
      "Pagination" => %{
        "MaxPageSizeAllowed" => 1000,
        "PageSize" => 100,
        "Result" => 1,
        "ResultWithoutFilter" => 2,
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
    expect(Dinero.DineroApiMock, :authentication, fn _, _, _ ->
      {:ok, %{"access_token" => "abc"}}
    end)

    expect(Dinero.DineroApiMock, :get_contacts, fn _, _, _ ->
      {:ok, contacts_response}
    end)

    expect(Dinero.DineroApiMock, :create_invoice, fn _, _, _ ->
      {:ok, nil}
    end)

    conn = post(conn, "/webhooks/invoice", webhook_data)
    assert json_response(conn, 200) == %{"message" => "Ok"}
  end
end
