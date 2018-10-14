defmodule JobplannerDinero.Account.Business do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Account.Business

  schema "account_businesses" do
    field(:name, :string)
    field(:email, :string)

    many_to_many(
      :users,
      JobplannerDinero.Account.User,
      join_through: "account_users_businesses"
    )

    timestamps()
  end

  def changeset(%Business{} = business, params) do
    business
    |> cast(params, [:name, :email])
    |> validate_required([:name])
    |> validate_format(:email, ~r/@/)
  end
end
