defmodule JobplannerDinero.Account.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.User

  schema "account_users" do
    field(:jobplanner_id, :integer)
    field(:email, :string)
    field(:username, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:jobplanner_access_token, :string)

    many_to_many(
      :businesses,
      JobplannerDinero.Account.Business,
      join_through: "account_users_businesses",
      on_replace: :delete
    )

    timestamps()
  end

  def changeset(%User{} = user, params) do
    user
    |> cast(params, [
      :jobplanner_id,
      :username,
      :first_name,
      :last_name,
      :email,
      :jobplanner_access_token
    ])
    |> validate_required([:jobplanner_id, :username, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end

  def registration_changeset(model, params \\ %{}) do
    model
    |> changeset(params)
  end

  def upsert_by(%User{} = record_struct, selector) do
    case User |> Repo.get_by(%{selector => record_struct |> Map.get(selector)}) do
      # build new user struct
      nil ->
        %User{}

      # pass through existing user struct
      user ->
        user
    end
    |> User.changeset(record_struct |> Map.from_struct())
    |> Repo.insert_or_update()
  end

  def upsert_by!(%User{} = record_struct, selector) do
    {:ok, user} = upsert_by(record_struct, selector)
    user
  end

  def get_business(user, id) do
    Enum.find(user.businesses, fn b -> b.id == id end)
  end
end
