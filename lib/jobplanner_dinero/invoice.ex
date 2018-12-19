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

  def to_dinero_invoice(%Invoice{invoice: invoice}, contact_id) do
    %Dinero.DineroInvoice{
      ContactGuid: contact_id,
      Date: Date.utc_today(),
      ProductLines: Enum.flat_map(invoice["visits"], fn visit ->
        Enum.map(visit["line_items"], &line_item_to_product_line/1)
      end)
    }
  end

  defp line_item_to_product_line(line_item) do
    %Dinero.DineroProductLine{
      BaseAmountValue: Map.get(line_item, "unit_cost"),
      Quantity: Map.get(line_item, "quantity"),
      AccountNumber: 1000,
      Description: Map.get(line_item, "name"),
      Comments: Map.get(line_item, "description"),
      LineType: "Product",
      Unit: "session"
    }
  end
end
