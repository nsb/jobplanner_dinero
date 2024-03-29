defmodule JobplannerDinero.Mixfile do
  use Mix.Project

  def project do
    [
      app: :jobplanner_dinero,
      version: "0.0.1",
      elixir: "~> 1.9.1",
      elixirc_paths: elixirc_paths(Mix.env),
      elixirc_options: [warnings_as_errors: true],
      compilers: [:phoenix, :gettext] ++ Mix.compilers, #  ++ [:cldr],
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {JobplannerDinero.Application, []},
      extra_applications: [:logger, :runtime_tools, :oauth2, :timex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:ecto_sql, "~> 3.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:oauth2, "~> 0.9"},
      {:jason, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:httpoison, "~> 1.4"},
      {:mox, "~> 0.4"},
      {:nimble_parsec, "~> 0.4.0"},
      # {:ex_cldr_dates_times, "~> 1.4.0"},
      {:distillery, "~> 2.0"},
      {:timex, "~> 3.4.2"},
      {:ex_dinero, "~> 0.1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
