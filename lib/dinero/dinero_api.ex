defmodule Dinero.DineroContact do
  use Ecto.Schema
  alias Dinero.DineroContact
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :ExternalReference,
             :Name,
             :Street,
             :ZipCode,
             :City,
             :CountryKey,
             :Phone,
             :Email,
             :isPerson
           ]}
  embedded_schema do
    field(:ExternalReference, :string)
    field(:Name, :string)
    field(:Street, :string)
    field(:ZipCode, :string)
    field(:City, :string)
    field(:CountryKey, :string)
    field(:Phone, :string)
    field(:Email, :string)
    field(:Webpage, :string)
    field(:AttPerson, :string)
    field(:VatNumber, :string)
    field(:EanNumber, :string)
    field(:PaymentConditionType, :string)
    field(:PaymentConditionNumberOfDays, :integer)
    field(:isPerson, :boolean)
  end

  def changeset(%DineroContact{} = contact, params) do
    contact
    |> cast(params, [
      :ExternalReference,
      :Name,
      :Street,
      :ZipCode,
      :City,
      :CountryKey,
      :Phone,
      :Email,
      :Webpage,
      :AttPerson,
      :VatNumber,
      :EanNumber,
      :PaymentConditionType,
      :PaymentConditionNumberOfDays,
      :isPerson
    ])
    |> validate_required([:Name, :CountryKey, :isPerson])
  end
end

defmodule Dinero.DineroProductLine do
  @behaviour Ecto.Type
  import Ecto.Changeset
  alias Dinero.DineroProductLine

  use Ecto.Schema

  @derive {Jason.Encoder,
           only: [
             :BaseAmountValue,
             :Description,
             :Comments,
             :Quantity,
             :AccountNumber,
             :Unit,
             :LineType
           ]}
  embedded_schema do
    field(:BaseAmountValue, :decimal)
    field(:ProductGuid, :string)
    field(:Description, :string)
    field(:Comments, :string)
    field(:Quantity, :decimal)
    field(:AccountNumber, :integer)
    field(:Unit, :string)
    field(:Discount, :decimal)
    field(:LineType, :string)
  end

  def changeset(%DineroProductLine{} = product_line, params) do
    product_line
    |> cast(params, [
      :BaseAmountValue,
      :ProductGuid,
      :Description,
      :Comments,
      :Quantity,
      :AccountNumber,
      :Unit,
      :Discount,
      :LineType
    ])
    |> validate_required([:BaseAmountValue, :Quantity])
  end

  def type, do: :map

  def cast(product_line) do
    product_line
  end

  def load(data) do
    data
  end

  def dump(data) do
    data
  end
end

defmodule Dinero.DineroInvoice do
  use Ecto.Schema
  alias Dinero.DineroInvoice
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:ContactGuid, :Date, :ProductLines]}
  embedded_schema do
    field(:ContactGuid, :string)
    field(:ExternalReference, :string)
    field(:Date, :date)
    field(:ProductLines, {:array, Dinero.DineroProductLine})
  end

  def changeset(%DineroInvoice{} = invoice, params) do
    invoice
    |> cast(params, [
      :ContactGuid,
      :ExternalReference,
      :Date,
      :ProductLines
    ])
    |> validate_required([:ContactGuid, :Date, :ProductLines])
  end
end

defmodule Dinero.DineroApi do
  @behaviour Dinero.DineroApiBehaviour
  use HTTPoison.Base
  alias Dinero.DineroContact

  @endpoint "https://api.dinero.dk/v1"

  def process_request_url(url) do
    @endpoint <> url
  end

  def authentication(client_id, client_secret, api_key) do
    encoded_client_id_and_secret = Base.encode64("#{client_id}:#{client_secret}")

    url = "https://authz.dinero.dk/dineroapi/oauth/token"

    body =
      URI.encode_query(%{
        "grant_type" => "password",
        "scope" => "read write",
        "username" => api_key,
        "password" => api_key
      })

    headers = [
      {"Authorization", "Basic #{encoded_client_id_and_secret}"},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body}} ->
        Jason.decode(body)

      {:error, error} ->
        {:error, error}
    end
  end

  def get_contacts(dinero_id, access_token, params) do
    url = "/#{dinero_id}/contacts"

    headers = [
      Authorization: "Bearer #{access_token}",
      "Content-Type": "application/json"
    ]

    case get(url, headers, params: params) do
      {:ok, %HTTPoison.Response{body: body}} ->
        Jason.decode(body)

      {:error, error} ->
        {:error, error}
    end
  end

  def create_contact(dinero_id, access_token, %DineroContact{} = contact) do
    url = "/#{dinero_id}/contacts"

    headers = [
      Authorization: "Bearer #{access_token}",
      "Content-Type": "application/json"
    ]

    body = Jason.encode!(contact)

    case post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}}
      when status_code in 200..299 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{body: body} = _response} ->
        {:error, Jason.decode!(body)}

      {:error, error} ->
        {:error, error}
    end
  end

  def create_invoice(
        dinero_id,
        access_token,
        %Dinero.DineroInvoice{} = invoice
      ) do
    url = "/#{dinero_id}/invoices"

    headers = [
      Authorization: "Bearer #{access_token}",
      "Content-Type": "application/json"
    ]

    body = Jason.encode!(invoice)

    case post(url, body, headers) do
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}}
      when status_code in 200..299 ->
        Jason.decode(body)

      {:ok, %HTTPoison.Response{body: body}} ->
        {:error, Jason.decode!(body)}

      {:error, error} ->
        {:error, error}
    end
  end
end
