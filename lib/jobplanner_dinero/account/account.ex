defmodule JobplannerDinero.Account do
  @moduledoc """
  The boundary for the Account system.
  """

  import Ecto.Query, warn: false
  alias JobplannerDinero.Repo
  alias JobplannerDinero.Account.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(
      from(
        u in "account_users",
        order_by: u.inserted_at,
        select: %{
          id: u.id,
          username: u.username,
          first_name: u.first_name,
          last_name: u.last_name,
          email: u.email,
          jobplanner_access_token: u.jobplanner_access_token
        }
      )
    )
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id),
    do:
      Repo.one(
        from(
          u in "account_users",
          where: u.id == ^String.to_integer(id),
          select: %{
            id: u.id,
            username: u.username,
            first_name: u.first_name,
            last_name: u.last_name,
            email: u.email,
            jobplanner_access_token: u.jobplanner_access_token
          }
        )
      )

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def get_by(username) do
    Repo.get_by(User, username: username)
  end

  def get_by_token(token) do
    Repo.get_by(User, token: token)
  end

  def get!(id) do
    Repo.get!(User, id)
  end
end
