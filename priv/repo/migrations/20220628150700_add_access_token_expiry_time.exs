defmodule JobplannerDinero.Repo.Migrations.AddTokenExpiryTime do
  use Ecto.Migration

  def change do
    alter table(:account_businesses) do
      add(:dinero_access_token_expires, :utc_datetime)
      add(:dinero_refresh_token_expires, :utc_datetime)
    end
  end
end
