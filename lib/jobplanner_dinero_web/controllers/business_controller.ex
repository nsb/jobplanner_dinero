defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller
  require Logger
  alias JobplannerDinero.Repo
  alias JobplannerDineroWeb.JobplannerOAuth2
  alias JobplannerDineroWeb.DineroOAuth2
  alias JobplannerDinero.Auth.Authorizer
  alias JobplannerDinero.Account.User
  alias JobplannerDinero.Account.Business

  @dinero_api Application.get_env(:jobplanner_dinero, :dinero_api)
  @dinero_client_id System.get_env("DINERO_CLIENT_ID2")
  @dinero_client_secret System.get_env("DINERO_CLIENT_SECRET2")

  plug(JobplannerDineroWeb.Plugs.AuthenticateUser when action in [:index, :show])
  plug(:authorize_user when action in [:show, :edit, :update])

  def index(conn, _params) do
    businesses = conn.assigns[:current_user].businesses

    case length(businesses) do
      1 ->
        redirect(conn, to: Routes.business_path(conn, :show, Enum.at(businesses, 0)))

      _ ->
        render(conn, "index.html")
    end
  end

  def show(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))
    changeset = Business.change_business(business)
    render(conn, "show.html", authorize_url: DineroOAuth2.authorize_url!(), business: business, changeset: changeset)
  end

  def edit(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))
    changeset = Business.change_business(business)
    render(conn, "edit.html", business: business, changeset: changeset)
  end

  def update(conn, %{"id" => id, "business" => business_params}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    business
    |> Business.changeset(business_params)
    |> Repo.update()
    |> case do
      {:ok, business} ->
        conn
        |> put_flash(:info, "Opdateret successfuldt")
        |> redirect(to: Routes.business_path(conn, :show, business))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", business: business, changeset: changeset)
    end
  end

  def activate(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    client = JobplannerOAuth2.client(conn.assigns.current_user.jobplanner_access_token)

    Business.delete_invoice_webhook(client, business)

    case client
         |> OAuth2.Client.put_header("Content-Type", "application/json")
         |> Business.create_invoice_webhook(business) do
      {:ok, business} ->
        if business.import_contacts_to_jobplanner do
          # Start importing Dinero contacts to myJobPlanner
          Task.Supervisor.start_child(
            JobplannerDinero.SyncAllContactsToMyJobPlannerSupervisor,
            fn ->
              import_dinero_contacts_to_myjobplanner(conn.assigns.current_user, business)
            end,
            restart: :transient
          )
        end

        conn
        |> put_flash(:info, "Aktiverede Dinero integration successfuldt")
        |> redirect(to: Routes.business_path(conn, :show, business))
        |> halt()

      {:error, _} ->
        conn
        |> put_flash(:error, "Kunne ikke aktivere webhook")
        |> redirect(to: Routes.business_path(conn, :show, business))
        |> halt()
    end
  end

  def deactivate(conn, %{"id" => id}) do
    business = User.get_business(conn.assigns.current_user, String.to_integer(id))

    client = JobplannerOAuth2.client(conn.assigns.current_user.jobplanner_access_token)

    case Business.delete_invoice_webhook(client, business) do
      {:ok, business} ->
        conn
        |> put_flash(:info, "Deaktiverede Dinero integration successfuldt")
        |> redirect(to: Routes.business_path(conn, :show, business))
        |> halt()

      {:error, _} ->
        conn
        |> put_flash(:error, "Kunne ikke deaktivere Dinero integration")
        |> redirect(to: Routes.business_path(conn, :show, business))
        |> halt()
    end
  end

  defp import_dinero_contacts_to_myjobplanner(user, business) do
    contact_fields =
      "Name,ContactGuid,ExternalReference,IsPerson,Street,ZipCode,City,CountryKey,Phone,Email,Webpage,AttPerson,VatNumber,EanNumber,PaymentConditionType,PaymentConditionNumberOfDays,IsMember,MemberNumber,CreatedAt,UpdatedAt,DeletedAt"

    Logger.info("Starting import of dinero contacts to myJobPlanner for #{business.name}...")

    client =
      JobplannerOAuth2.client(user.jobplanner_access_token)
      |> OAuth2.Client.put_header("Content-Type", "application/json")

    with {:ok, %{"access_token" => access_token}} <-
           @dinero_api.authentication(
             @dinero_client_id,
             @dinero_client_secret,
             business.dinero_api_key
           ),
         {:ok, %{"Collection" => contacts}} <-
           @dinero_api.get_contacts(business.dinero_id, access_token, fields: contact_fields) do
      # Do not import contacts created by myJobPlanner
      filtered_contacts =
        Enum.filter(contacts, fn c ->
          cond do
            c["ExternalReference"] == nil ->
              true

            String.starts_with?(c["ExternalReference"], "myjobplanner:") ->
              false
          end
        end)

      Logger.info(
        "Importing #{length(filtered_contacts)} contacts from dinero to #{business.name}..."
      )

      Enum.each(
        filtered_contacts,
        fn contact ->
          contact_name = String.split(contact["Name"], " ", parts: 2, trim: true)

          Task.Supervisor.start_child(
            JobplannerDinero.SyncOneContactToMyJobPlannerSupervisor,
            fn ->
              # First check if the client already exists in jobplanner
              case Business.get_jobplanner_clients(client, %{
                     "business" => business.jobplanner_id,
                     "external_id" => contact["ContactGuid"]
                   }) do
                {:ok, %OAuth2.Response{body: %{"count" => count}}}
                when count == 0 ->
                  # If the client does not exist, we go ahead and create it

                  body = %{
                    "business" => business.jobplanner_id,
                    "first_name" => Enum.at(contact_name, 0),
                    "last_name" => Enum.at(contact_name, 1, ""),
                    "address1" => contact["Street"],
                    "city" => contact["City"],
                    "zip_code" => contact["ZipCode"],
                    "country" => contact["CountryKey"],
                    "address_use_property" => true,
                    "email" => contact["Email"],
                    "phone" => contact["Phone"],
                    "properties" => [
                      %{
                        "address1" => contact["Street"],
                        "city" => contact["City"],
                        "zip_code" => contact["ZipCode"],
                        "country" => contact["CountryKey"]
                      }
                    ],
                    "upcoming_visit_reminder_email_enabled" => true,
                    "external_id" => contact["ContactGuid"],
                    "imported_from" => "dinero",
                    "imported_via" => "myJobPlanner Dinero integration",
                    "is_business" => not contact["IsPerson"],
                    "business_name" => (not contact["IsPerson"] && contact["Name"]) || ""
                  }

                  case OAuth2.Client.post(
                         client,
                         "https://api.myjobplanner.com/v1/clients/",
                         body
                       ) do
                    {:ok, response} ->
                      Logger.info(
                        "Successfully imported contact #{contact["Name"]} with id #{
                          response.body["id"]
                        }"
                      )

                    {:error, error} ->
                      {:error, error}
                  end

                {:ok, response} ->
                  Logger.info(
                    "Skipping import of #{contact["Name"]} with Guid #{contact["ContactGuid"]}"
                  )

                  {:ok, response}
              end
            end,
            restart: :transient
          )
        end
      )
    else
      {:error, error} ->
        error
    end
  end

  defp authorize_user(conn, _params) do
    %{params: %{"id" => business_id}} = conn

    if Authorizer.can_manage?(conn.assigns.current_user, String.to_integer(business_id)) do
      conn
    else
      conn
      |> put_flash(:error, "Du har ikke adgang til denne side")
      |> redirect(to: Routes.business_path(conn, :index))
      |> halt()
    end
  end
end
