defmodule JobplannerDineroWeb.JobplannerOAuth2 do
  use OAuth2.Strategy

  # Public API

  def client(token \\ nil) do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: System.get_env("JOBPLANNER_CLIENT_ID"),
      client_secret: System.get_env("JOBPLANNER_CLIENT_SECRET"),
      redirect_uri: System.get_env("REDIRECT_URI") || "https://localhost:4000/auth/jobplanner/callback",
      site: "https://auth.myjobplanner.com",
      authorize_url: "https://auth.myjobplanner.com/o/authorize/",
      token_url: "https://auth.myjobplanner.com/o/token/",
      token: token
    ])
  end

  @spec authorize_url!() :: binary()
  def authorize_url! do
    OAuth2.Client.authorize_url!(client(), scope: "read write")
  end

  # you can pass options to the underlying http library via `opts` parameter
  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    OAuth2.Client.get_token!(client(), params, headers, opts)
  end

  # Strategy Callbacks

  @spec authorize_url(
          OAuth2.Client.t(),
          keyword()
          | %{
              optional(binary()) =>
                binary()
                | [binary() | [any()] | %{optional(binary()) => any()}]
                | %{optional(binary()) => binary() | [any()] | %{optional(binary()) => any()}}
            }
        ) :: OAuth2.Client.t()
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @spec get_token(OAuth2.Client.t(), keyword(), [{binary(), binary()}]) :: OAuth2.Client.t()
  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_param(:grant_type, "authorization_code")
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
