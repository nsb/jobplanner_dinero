defmodule JobplannerDinero.Invoice do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Invoice

  schema "invoices" do
    field :invoice, :map
    belongs_to :business, JobplannerDinero.Account.Business

    timestamps()
  end

  def changeset(%Invoice{} = invoice, params) do
    invoice
    |> cast(params, [:business, :invoice])
    |> validate_required([:business, :invoice])
  end

  def create_invoice(attrs \\ %{}) do
    %Invoice{business_id: attrs["business"], invoice: attrs}
    |> Ecto.Changeset.change()
    |> Repo.insert()
  end
end
