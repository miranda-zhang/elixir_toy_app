defmodule Backend.Accounts do
  import Ecto.Query, warn: false
  alias Backend.Repo
  alias Backend.Accounts.User
  alias Bcrypt

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def authenticate_user(email, password) do
    with %User{} = user <- get_user_by_email(email),
         true <- Bcrypt.verify_pass(password, user.hashed_password) do
      {:ok, user}
    else
      _ -> {:error, "Invalid email or password"}
    end
  end

  def update_phone_number(user_id, phone_number) do
    user = Repo.get!(User, user_id)

    user
    |> Ecto.Changeset.change(phone_number: phone_number)
    |> Repo.update()
  end
end
