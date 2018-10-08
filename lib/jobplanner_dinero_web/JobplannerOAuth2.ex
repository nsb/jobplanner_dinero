defmodule JobplannerDineroWeb.JobplannerOAuth2 do
  use OAuth2.Strategy

  # Public API

  def client do
    OAuth2.Client.new([
      strategy: __MODULE__,
      client_id: System.get_env("JOBPLANNER_CLIENT_ID"),
      client_secret: System.get_env("JOBPLANNER_CLIENT_SECRET"),
      redirect_uri: "https://tolocalhost.com/auth/jobplanner/callback",
      site: "https://api.myjobplanner.com",
      authorize_url: "https://api.myjobplanner.com/o/authorize/",
      token_url: "https://api.myjobplanner.com/o/token/"
    ])
  end

  def authorize_url! do
    OAuth2.Client.authorize_url!(client(), scope: "read write")
  end

  # you can pass options to the underlying http library via `opts` parameter
  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    OAuth2.Client.get_token!(client(), params, headers, opts)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_param(:grant_type, "authorization_code")
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
