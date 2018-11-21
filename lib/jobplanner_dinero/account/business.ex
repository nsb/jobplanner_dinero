defmodule JobplannerDinero.Account.Business do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.Business

  schema "account_businesses" do
    field(:jobplanner_id, :integer)
    field(:dinero_api_key, :string)
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
    |> cast(params, [:jobplanner_id, :name, :email])
    |> validate_required([:name])
    |> validate_format(:email, ~r/@/)
  end

  def upsert_by(%Business{} = record_struct, selector) do
    case Business |> Repo.get_by(%{selector => record_struct |> Map.get(selector)}) do
      nil -> %Business{} # build new user struct
      business -> business   # pass through existing user struct
    end
    |> Business.changeset(record_struct |> Map.from_struct)
    |> Repo.insert_or_update
  end

  def upsert_by!(%Business{} = record_struct, selector) do
    {:ok, business} = upsert_by(record_struct, selector)
    business
  end
end
