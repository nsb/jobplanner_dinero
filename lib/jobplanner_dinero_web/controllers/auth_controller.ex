defmodule JobplannerDineroWeb.AuthController do
  use JobplannerDineroWeb, :controller

  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.User
  alias JobplannerDinero.Account.Business
  alias JobplannerDineroWeb.JobplannerOAuth2

  @doc """
  This action is reached via `/auth/:provider` and redirects to the OAuth2 provider
  based on the chosen strategy.
  """
  def index(conn, %{"provider" => provider}) do
    redirect(conn, external: authorize_url!(provider))
  end

  @spec delete(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Du er logget ud!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  @doc """
  This action is reached via `/auth/:provider/callback` is the the callback URL that
  the OAuth2 provider will redirect the user back to with a `code` that will
  be used to request an access token. The access token will then be used to
  access protected resources on behalf of the user.
  """
  def callback(conn, %{"provider" => provider, "code" => code}) do
    # Exchange an auth code for an access token
    client = get_token!(provider, code)

    {:ok, response} =
      Repo.transaction(fn ->
        # Request the users businesses and save them.
        businesses =
          get_businesses!(provider, client)
          |> Enum.map(fn business ->
            Business.upsert_by!(business, :jobplanner_id) |> Repo.preload(:users)
          end)

        # Request the user's data with the access token and save the user with associated businesses.
        user =
          get_user!(provider, client)
          |> User.upsert_by!(:jobplanner_id)
          |> Repo.preload(:businesses)
          |> Ecto.Changeset.change()
          |> Ecto.Changeset.put_assoc(:businesses, businesses )
          |> Repo.update!()

        # Save the user id in the session under `:current_user` and redirect to /
        conn
        |> put_session(:current_user_id, user.id)
        |> redirect(to: "/")
      end)

    response
  end

  defp authorize_url!("jobplanner"), do: JobplannerOAuth2.authorize_url!()
  defp authorize_url!(_), do: raise("No matching provider available")

  defp get_token!("jobplanner", code), do: JobplannerOAuth2.get_token!(code: code)
  defp get_token!(_, _), do: raise("No matching provider available")

  defp get_user!("jobplanner", client) do
    %{body: user} = OAuth2.Client.get!(client, "https://api.myjobplanner.com/v1/users/me/")

    %User{
      jobplanner_id: user["id"],
      username: user["username"],
      first_name: user["first_name"],
      last_name: user["last_name"],
      email: user["email"],
      jobplanner_access_token: client.token.access_token
    }
  end

  defp get_businesses!("jobplanner", client) do
    %{body: %{"results" => businesses}} =
      OAuth2.Client.get!(client, "https://api.myjobplanner.com/v1/businesses/")

    Enum.map(businesses, fn business ->
      %{
        jobplanner_id: business["id"],
        name: business["name"],
        email: business["email"]
      }
    end)
  end
end
