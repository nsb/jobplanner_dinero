defmodule JobplannerDinero.Account.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Account.User

  schema "account_users" do
    field(:email, :string)
    field(:username, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:jobplanner_access_token, :string)

    many_to_many(
      :businesses,
      JobplannerDinero.Account.Business,
      join_through: "account_users_businesses"
    )

    timestamps()
  end

  def changeset(%User{} = user, params) do
    user
    |> cast(params, [:username, :first_name, :last_name, :email, :jobplanner_access_token])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def registration_changeset(model, params \\ %{}) do
    model
    |> changeset(params)
  end
end
