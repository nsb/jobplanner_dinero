defmodule JobplannerDinero.Repo.Migrations.AddImportContacts do
  use Ecto.Migration

  def change do
    alter table(:account_businesses) do
      add :import_contacts_to_jobplanner, :boolean, default: true
    end
  end
end
