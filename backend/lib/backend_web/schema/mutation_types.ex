defmodule BackendWeb.Schema.MutationTypes do
  use Absinthe.Schema.Notation
  alias Backend.Accounts
  alias Backend.Auth.Token

  object :user_mutations do
    field :register_user, type: :user do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve fn args, _ ->
        case Accounts.register_user(args) do
          {:ok, user} -> {:ok, user}
          {:error, _changeset} -> {:error, "Registration failed"}
        end
      end
    end

    field :login_user, type: :string do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve fn %{email: email, password: password}, _ ->
        case Accounts.authenticate_user(email, password) do
          {:ok, user} ->
            token = Token.generate(user)
            {:ok, token}

          {:error, msg} ->
            {:error, msg}
        end
      end
    end
  end
end
