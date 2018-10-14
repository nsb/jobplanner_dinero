defmodule JobplannerDinero.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:account_users) do
      add(:jobplanner_id, :integer, null: false)
      add(:username, :string, null: false)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:email, :string)
      add(:jobplanner_access_token, :string)

      timestamps()
    end

    create(unique_index(:account_users, [:jobplanner_id]))
    create(unique_index(:account_users, [:username]))
  end
end
