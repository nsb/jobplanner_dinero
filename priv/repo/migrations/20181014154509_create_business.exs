defmodule JobplannerDinero.Repo.Migrations.CreateBusiness do
  use Ecto.Migration

  def change do
    create table(:account_businesses) do
      add(:jobplanner_id, :integer)
      add(:name, :string, null: false)
      add(:email, :string)

      timestamps()
    end

    create(unique_index(:account_businesses, [:jobplanner_id]))
  end
end
