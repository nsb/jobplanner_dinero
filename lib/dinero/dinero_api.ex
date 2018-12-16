defmodule Dinero.DineroProductLine do
  @behaviour Ecto.Type
  import Ecto.Changeset
  alias Dinero.DineroProductLine

  use Ecto.Schema

  @derive {Jason.Encoder, only: [:BaseAmountValue, :Description, :Quantity, :AccountNumber, :Unit, :LineType]}
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

  @derive {Jason.Encoder, only: [:ContactGuid, :Date, :ProductLines]}
  embedded_schema do
    field(:ContactGuid, :string)
    field(:ExternalReference, :string)
    field(:Date, :date)
    field(:ProductLines, {:array, Dinero.DineroProductLine})
  end
end

defmodule Dinero.DineroApi do
  @behaviour Dinero.DineroApiBehaviour
  use HTTPoison.Base

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

    case get(url, headers, params) do
      {:ok, %HTTPoison.Response{body: body}} ->
        Jason.decode(body)

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
