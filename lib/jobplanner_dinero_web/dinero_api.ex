defmodule JobplannerDineroWeb.DineroApi do
  @behaviour JobplannerDineroWeb.DineroApiBehaviour
  use HTTPoison.Base

  @endpoint "https://api.dinero.dk/v1"

  def process_request_url(url) do
    @endpoint <> url
  end

  def authentication(client_id, client_secret, api_key) do
    encoded_client_id_and_secret = Base.encode64("#{client_id}:#{client_secret}")

    url = "https://authz.dinero.dk/dineroapi/oauth/token"
    body = URI.encode_query(%{"grant_type" => "password", "scope" => "read write", "username" => api_key, "password" => api_key})
    headers = [{"Authorization", "Basic #{encoded_client_id_and_secret}"}, {"Content-Type", "application/x-www-form-urlencoded"}]
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
end
