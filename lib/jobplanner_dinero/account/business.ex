defmodule JobplannerDinero.Account.Business do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.Business

  @webhook_url "https://api.myjobplanner.com/v1/hooks/"

  schema "account_businesses" do
    field(:jobplanner_id, :integer)
    field(:jobplanner_webhook_id, :integer)
    field(:dinero_api_key, :string)
    field(:is_active, :boolean, default: false)
    field(:name, :string)
    field(:email, :string)

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
      :jobplanner_webhook_id,
      :dinero_api_key,
      :is_active,
      :name,
      :email
    ])
    |> validate_required([:jobplanner_id, :name])
    |> validate_format(:email, ~r/@/)
  end

  def upsert_by(%Business{} = record_struct, selector) do
    case Business |> Repo.get_by(%{selector => record_struct |> Map.get(selector)}) do
      # build new business struct
      nil ->
        %Business{}

      # pass through existing business struct
      business ->
        business
    end
    |> Business.changeset(record_struct |> Map.from_struct())
    |> Repo.insert_or_update()
  end

  def upsert_by!(%Business{} = record_struct, selector) do
    {:ok, business} = upsert_by(record_struct, selector)
    business
  end

  def change_business(%Business{} = business) do
    Business.changeset(business, %{})
  end

  def create_invoice_webhook(client, business) do
    body = %{
      "business" => business.id,
      "target" => "http://requestbin.fullcontact.com/15svnt81",
      "event" => "invoice.added",
      "is_active" => true
    }

    case OAuth2.Client.post(client, @webhook_url, body) do
      {:ok, %{body: hook}} ->
        Ecto.Changeset.change(business, jobplanner_webhook_id: hook["id"])
        |> Repo.update
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
    case OAuth2.Client.delete(client, "#{@webhook_url}#{business.jobplanner_webhook_id}/") do
      {:ok, _} ->
        Ecto.Changeset.change(business, jobplanner_webhook_id: nil)
        |> Repo.update
      {:error, error} ->
        {:error, error}
    end
  end

  def delete_invoice_webhook!(client, business) do
    case delete_invoice_webhook(client, business) do
      {:ok, business} -> business
      {:error, error} -> raise error
    end
  end
end
