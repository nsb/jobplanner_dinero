defmodule JobplannerDinero.Invoice do
  use Ecto.Schema
  use Timex
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.Business
  alias JobplannerDinero.Invoice

  schema "invoices" do
    field(:dinero_id, :string)
    field(:invoice, :map)
    field(:synced, :utc_datetime)
    belongs_to(:business, JobplannerDinero.Account.Business)

    timestamps()
  end

  def changeset(%Invoice{} = invoice, params) do
    invoice
    |> cast(params, [:invoice, :dinero_id, :synced])
    |> cast_assoc(:business)
    |> validate_required([:business, :invoice])
    |> foreign_key_constraint(:business)
  end

  def create_invoice(%{"business" => business_id} = attrs) do
    case Repo.get_by(Business, jobplanner_id: business_id) do
      nil ->
        {:error, "Business not found"}

      business ->
        %Invoice{business_id: business.id, invoice: attrs}
        |> Ecto.Changeset.change()
        |> Repo.insert()
    end
  end

  def to_dinero_invoice(%Invoice{invoice: invoice}, contact_id) do
    %Dinero.DineroInvoice{
      ContactGuid: contact_id,
      Date: Date.utc_today(),
      ProductLines:
        Enum.flat_map(invoice["visits"], fn visit ->
          Enum.map(visit["line_items"], fn line_item ->
            {:ok, date, _offset } = DateTime.from_iso8601(visit["begins"])
            %{line_item_to_product_line(line_item) | Comments: Enum.join([date.year, date.month, date.day], "/")}
          end)
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
