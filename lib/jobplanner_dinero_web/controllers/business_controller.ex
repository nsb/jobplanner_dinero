defmodule JobplannerDineroWeb.BusinessController do
  use JobplannerDineroWeb, :controller
  alias JobplannerDinero.Repo
  alias JobplannerDineroWeb.JobplannerOAuth2
  alias JobplannerDinero.Auth.Authorizer
  alias JobplannerDinero.Account.User
  alias JobplannerDinero.Account.Business

  @dinero_api Application.get_env(:jobplanner_dinero, :dinero_api)
  @dinero_client_id System.get_env("DINERO_CLIENT_ID")
  @dinero_client_secret System.get_env("DINERO_CLIENT_SECRET")

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

    case business.dinero_api_key do
      nil ->
        redirect(conn, to: Routes.business_path(conn, :edit, business))

      _ ->
        changeset = Business.change_business(business)
        render(conn, "show.html", business: business, changeset: changeset)
    end
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
        # Start importing Dinero contacts to myJobPlanner
        Task.Supervisor.start_child(
          JobplannerDinero.SyncContactsToMyJobPlannerSupervisor,
          fn ->
            import_dinero_contacts_to_myjobplanner(
              business.dinero_id,
              business.dinero_api_key,
              business.jobplanner_id,
              conn.assigns.current_user.jobplanner_access_token
            )
          end,
          restart: :transient
        )

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

  def import_dinero_contacts_to_myjobplanner(
        dinero_id,
        dinero_api_key,
        jobplanner_business_id,
        jobplanner_access_token
      ) do
    contact_fields =
      "Name,ContactGuid,ExternalReference,IsPerson,Street,ZipCode,City,CountryKey,Phone,Email,Webpage,AttPerson,VatNumber,EanNumber,PaymentConditionType,PaymentConditionNumberOfDays,IsMember,MemberNumber,CreatedAt,UpdatedAt,DeletedAt"

    client =
      JobplannerOAuth2.client(jobplanner_access_token)
      |> OAuth2.Client.put_header("Content-Type", "application/json")

    with {:ok, %{"access_token" => access_token}} <-
           @dinero_api.authentication(
             @dinero_client_id,
             @dinero_client_secret,
             dinero_api_key
           ),
         {:ok, %{"Collection" => contacts}} <-
           @dinero_api.get_contacts(dinero_id, access_token, fields: contact_fields) do
      Enum.each(contacts, fn contact ->
        [first_name, last_name] = String.split(contact["Name"], " ", parts: 2, trim: true)

        body = %{
          "business" => jobplanner_business_id,
          "first_name" => first_name,
          "last_name" => last_name,
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
          "business_name" => "string"
        }

        case OAuth2.Client.post(client, "https://api.myjobplanner.com/v1/clients/", body) do
          {:ok, response} ->
            response

          {:error, error} ->
            {:error, error}
        end
      end)
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
