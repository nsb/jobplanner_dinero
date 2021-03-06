defmodule JobplannerDinero.Repo.Migrations.CreateBusiness do
  use Ecto.Migration

  def change do
    create table(:account_businesses) do
      add(:jobplanner_id, :integer, null: false)
      add(:dinero_id, :integer)
      add(:jobplanner_webhook_id, :integer)
      add(:dinero_api_key, :string)
      add(:dinero_access_token, :string)
      add(:is_active, :boolean, default: false)
      add(:name, :string, null: false)
      add(:email, :string)

      timestamps()
    end

    create(unique_index(:account_businesses, [:jobplanner_id]))
  end
end
