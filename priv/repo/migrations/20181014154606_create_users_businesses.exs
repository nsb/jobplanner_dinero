defmodule JobplannerDinero.Repo.Migrations.CreateUsersBusinesses do
  use Ecto.Migration

  def change do
    create table(:account_users_businesses) do
      add(:user_id, references(:account_users))
      add(:business_id, references(:account_businesses))
    end

    create(unique_index(:account_users_businesses, [:user_id, :business_id]))
  end
end
