defmodule JobplannerDineroWeb.DineroOAuth2 do
  use OAuth2.Strategy

  # Public API

  def client(token \\ nil) do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: System.get_env("DINERO_CLIENT_ID2"),
      client_secret: System.get_env("DINERO_CLIENT_SECRET2"),
      redirect_uri: System.get_env("DINERO_REDIRECT_URI2") || "https://dinero.myjobplanner.com/auth/dinero/callback",
      site: "https://connect.visma.com",
      authorize_url: "https://connect.visma.com/connect/authorize",
      token_url: "https://connect.visma.com/connect/token",
      token: token
    ])
  end

  def refresh_client(refresh_token \\ nil) do
    OAuth2.Client.new([
      strategy: OAuth2.Strategy.Refresh,
      client_id: System.get_env("DINERO_CLIENT_ID2"),
      client_secret: System.get_env("DINERO_CLIENT_SECRET2"),
      redirect_uri: System.get_env("DINERO_REDIRECT_URI2") || "https://dinero.myjobplanner.com/auth/dinero/callback",
      site: "https://connect.visma.com",
      authorize_url: "https://connect.visma.com/connect/authorize",
      token_url: "https://connect.visma.com/connect/token",
      params: %{"refresh_token" => refresh_token}
    ])
  end

  @spec authorize_url!() :: binary()
  def authorize_url! do
    OAuth2.Client.authorize_url!(client(), scope: "dineropublicapi:read dineropublicapi:write offline_access")
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
