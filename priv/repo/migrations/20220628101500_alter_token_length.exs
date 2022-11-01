defmodule JobplannerDinero.Repo.Migrations.AlterTokenLength do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE account_businesses ALTER COLUMN dinero_access_token TYPE varchar(2048)"
    execute "ALTER TABLE account_businesses ALTER COLUMN dinero_refresh_token TYPE varchar(2048)"
  end
end
