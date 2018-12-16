use Mix.Config

config :jobplanner_dinero,
  dinero_api: Dinero.DineroApiMock

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :jobplanner_dinero, JobplannerDineroWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :jobplanner_dinero, JobplannerDinero.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "",
  database: "jobplanner_dinero_test",
  hostname: "db",
  pool: Ecto.Adapters.SQL.Sandbox
