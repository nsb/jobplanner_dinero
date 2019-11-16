defmodule JobplannerDinero.Account.Business do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.Business

  @webhook_url "https://api.myjobplanner.com/v1/hooks/"

  schema "account_businesses" do
    field(:jobplanner_id, :integer)
    field(:dinero_id, :integer)
    field(:jobplanner_webhook_id, :integer)
    field(:dinero_api_key, :string)
    field(:dinero_access_token, :string)
    field(:is_active, :boolean, default: false)
    field(:import_contacts_to_jobplanner, :boolean, default: true)
    field(:name, :string)
    field(:email, :string)
    has_many(:invoices, JobplannerDinero.Invoice)
    many_to_many(
      :users,
      JobplannerDinero.Account.User,
      join_through: "account_users_businesses"
    )

    timestamps()
  end

  def changeset(%Business{} = business, params) do
    business
    |> cast(params, [
      :jobplanner_id,
      :dinero_id,
      :jobplanner_webhook_id,
      :dinero_api_key,
      :is_active,
      :import_contacts_to_jobplanner,
      :name,
      :email
    ])
    # |> update_change(:dinero_id, &String.trim/1)
    # |> update_change(:dinero_api_key, &String.trim/1)
    |> validate_required([:jobplanner_id, :name])
    |> validate_format(:email, ~r/@/)
  end

  def upsert_by(changes, selector) do
    case Business |> Repo.get_by(%{selector => changes |> Map.get(selector)}) do
      # build new business struct
      nil ->
        %Business{}

      # pass through existing business struct
      business ->
        business
    end
    |> Business.changeset(changes)
    |> Repo.insert_or_update()
  end

  def upsert_by!(changes, selector) do
    {:ok, business} = upsert_by(changes, selector)
    business
  end

  def change_business(%Business{} = business) do
    Business.changeset(business, %{})
  end

  def create_invoice_webhook(client, business) do
    body = %{
      "business" => business.jobplanner_id,
      "target" => "https://dinero.myjobplanner.com/webhooks/invoice",
      "event" => "invoice.added",
      "is_active" => true
    }

    case OAuth2.Client.post(client, @webhook_url, body) do
      {:ok, %{body: hook}} ->
        Ecto.Changeset.change(business, jobplanner_webhook_id: hook["id"], is_active: true)
        |> Repo.update()

      {:error, error} ->
        {:error, error}
    end
  end

  def create_invoice_webhook!(client, business) do
    case create_invoice_webhook(client, business) do
      {:ok, business} -> business
      {:error, error} -> raise error
    end
  end

  def delete_invoice_webhook(client, business) do
    if business.jobplanner_webhook_id do
      case OAuth2.Client.delete(client, "#{@webhook_url}#{business.jobplanner_webhook_id}/") do
        {:ok, _} ->
          Ecto.Changeset.change(business, jobplanner_webhook_id: nil, is_active: false)
          |> Repo.update()

        {:error, error} ->
          {:error, error}
      end
    else
      {:ok, business}
    end
  end

  def delete_invoice_webhook!(client, business) do
    case delete_invoice_webhook(client, business) do
      {:ok, business} -> business
      {:error, error} -> raise error
    end
  end

  def get_jobplanner_clients(client, params) do
    OAuth2.Client.get(client, "https://api.myjobplanner.com/v1/clients/", [], params: params)
  end

  def request_dinero_token(client_id, client_secret, api_key) do
    encoded_client_id_and_secret = Base.encode64("#{client_id}:#{client_secret}")
    case :hackney.request(
      :post,
      "https://authz.dinero.dk/dineroapi/oauth/token",
      [{"Authorization", "Basic #{encoded_client_id_and_secret}"}, {"Content-Type", "application/x-www-form-urlencoded"}],
      URI.encode_query(%{"grant_type" => "password", "scope" => "read write", "username" => api_key, "password" => api_key})
    ) do
      {:ok, status, _respheaders, client} when is_integer(status) and status in 200..299 ->
        {:ok, resp} = :hackney.body(client)
        Jason.decode(resp)
      {:ok, _status, _respheaders, client} ->
        {:ok, mesg} = :hackney.body(client)
        {:error, mesg}
      {:error, error} -> {:error, error}
    end
  end
end
