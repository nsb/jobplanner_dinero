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

  pipeline :webhook do
    plug :accepts, ["json"]
  end

  scope "/", JobplannerDineroWeb do
    pipe_through :browser # Use the default browser stack

    get "/", BusinessController, :index
    get "/business/:id", BusinessController, :show
    put "/business/:id", BusinessController, :update
    get "/business/:id/edit", BusinessController, :edit
    put "/business/:id/activate", BusinessController, :activate
    put "/business/:id/deactivate", BusinessController, :deactivate
    get "/oauth", OauthController, :index
  end

  scope "/auth", JobplannerDineroWeb do
    pipe_through :browser

    get "/:provider", AuthController, :index
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Other scopes may use custom stacks.
  scope "/webhooks", JobplannerDineroWeb do
    pipe_through :webhook

    post "/invoice", InvoiceController, :create
  end

  scope "/health", JobplannerDineroWeb do
    pipe_through :browser

    get("/liveness", HealthController, :index)
    get("/readiness", HealthController, :index)
  end
end
