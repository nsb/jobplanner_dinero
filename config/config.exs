# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :jobplanner_dinero,
  ecto_repos: [JobplannerDinero.Repo],
  dinero_api: Dinero.DineroApi

# Configures the endpoint
config :jobplanner_dinero, JobplannerDineroWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yINUmIBGGhi+lCUdSeaVxRpJrFV8yGSvfAPX/aG3izSOdYR+mrz/ulQZYkposhMk",
  render_errors: [view: JobplannerDineroWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: JobplannerDinero.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :oauth2, debug: true

config :phoenix, :json_library, Jason

# Configure your database
config :jobplanner_dinero, JobplannerDinero.Repo,
  username: System.get_env("DB_USERNAME") || "postgres",
  password: System.get_env("DB_PASSWORD") || "",
  database: System.get_env("DB_NAME") || "jobplanner_dinero_dev",
  hostname: System.get_env("DB_HOST") || "db",
  pool_size: 10

# config :ex_cldr,
#    default_locale: "en",
#    locales: ["en", "da"]

config :jobplanner_dinero, Jobplanner,
  client_id: System.get_env("JOBPLANNER_CLIENT_ID"),
  client_secret: System.get_env("JOBPLANNER_CLIENT_SECRET"),
  redirect_uri: System.get_env("JOBPLANNER_REDIRECT_URI")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
