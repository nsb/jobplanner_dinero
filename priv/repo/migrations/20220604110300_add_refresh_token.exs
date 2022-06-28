defmodule JobplannerDinero.Repo.Migrations.AddRefreshToken do
  use Ecto.Migration

  def change do
    alter table(:account_businesses) do
      add(:dinero_refresh_token, :string)
    end
  end
end
