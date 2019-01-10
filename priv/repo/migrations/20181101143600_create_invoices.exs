defmodule JobplannerDinero.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :dinero_id, :string
      add :invoice, :map
      add :business_id, references(:account_businesses, [column: :jobplanner_id]), null: false
      timestamps()
    end
  end
end
