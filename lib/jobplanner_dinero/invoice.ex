defmodule JobplannerDinero.Invoice do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Invoice

  schema "invoices" do
    field :dinero_id, :string
    field :invoice, :map
    belongs_to :business, JobplannerDinero.Account.Business

    timestamps()
  end

  def changeset(%Invoice{} = invoice, params) do
    invoice
    |> cast(params, [:business, :invoice])
    |> validate_required([:business, :invoice])
    |> foreign_key_constraint(:business)
  end

  def create_invoice(attrs \\ %{}) do
    %Invoice{business_id: attrs["business"], invoice: attrs}
    |> Ecto.Changeset.change()
    |> Repo.insert()
  end

  def to_dinero_invoice(%Invoice{} = _invoice, contact_id) do
    %Dinero.DineroInvoice{
      ContactGuid: contact_id,
      Date: Date.utc_today(),
      ProductLines: [
        %Dinero.DineroProductLine{
          BaseAmountValue: 20.0,
          Quantity: 5.0,
          AccountNumber: 1000,
          Description: "Standard rengøring",
          LineType: "Product",
          Unit: "session"
        }
      ]
    }
  end
end
