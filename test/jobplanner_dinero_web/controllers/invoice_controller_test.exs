defmodule JobplannerDineroWeb.InvoiceControllerTest do
  use JobplannerDineroWeb.ConnCase

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

    %{webhook_data: webhook_data, business: business}
  end

  test "CREATE /webhooks/invoice", %{conn: conn, webhook_data: webhook_data} do
    conn = post(conn, "/webhooks/invoice", webhook_data)
    assert text_response(conn, 200) =~ "Ok"
  end
end
