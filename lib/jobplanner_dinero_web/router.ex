defmodule JobplannerDineroWeb.Router do
  use JobplannerDineroWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JobplannerDineroWeb do
    pipe_through :browser # Use the default browser stack

    get "/", BusinessController, :index
    get "/business/:id", BusinessController, :show
    get "/oauth", OauthController, :index
  end

  scope "/auth", JobplannerDineroWeb do
    pipe_through :browser

    get "/:provider", AuthController, :index
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Fetch the current user from the session and add it to `conn.assigns`. This
  # will allow you to have access to the current user in your views with
  # `@current_user`.
  defp assign_current_user(conn, _) do
   assign(conn, :current_user, get_session(conn, :current_user))
  end

  # Other scopes may use custom stacks.
  # scope "/api", JobplannerDineroWeb do
  #   pipe_through :api
  # end
end
