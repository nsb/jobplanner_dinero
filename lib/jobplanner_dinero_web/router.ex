defmodule JobplannerDineroWeb.Router do
  use JobplannerDineroWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug JobplannerDineroWeb.Plugs.SetCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JobplannerDineroWeb do
    pipe_through :browser # Use the default browser stack

    get "/", BusinessController, :index
    get "/business/:id", BusinessController, :show
    get "/business/:id/edit", BusinessController, :edit
    put "/business/:id", BusinessController, :update
    get "/oauth", OauthController, :index
  end

  scope "/auth", JobplannerDineroWeb do
    pipe_through :browser

    get "/:provider", AuthController, :index
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", JobplannerDineroWeb do
  #   pipe_through :api
  # end
end
