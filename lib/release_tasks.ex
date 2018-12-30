defmodule JobplannerDinero.ReleaseTasks do
  def migrate do
   {:ok, _} = Application.ensure_all_started(:jobplanner_dinero)
    path = Application.app_dir(:jobplanner_dinero, "priv/repo/migrations")
    Ecto.Migrator.run(JobplannerDinero.Repo, path, :up, all: true)
  end
end
