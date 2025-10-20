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
          {:error, changeset} ->
            # Extract human-readable messages from the Ecto.Changeset
            {:error, format_changeset_errors(changeset)}
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

    field :add_phone_number, type: :user do
      arg :phone_number, non_null(:string)
      middleware BackendWeb.Middleware.Authenticate  # 👈 Require auth

      resolve fn %{phone_number: phone_number}, %{context: %{current_user: user}} ->
        case Backend.Accounts.update_phone_number(user.id, phone_number) do
          {:ok, updated_user} -> {:ok, updated_user}
          {:error, _changeset} -> {:error, "Failed to update phone number"}
        end
      end
    end
  end

  # 👇 Helper function lives *inside* this module (not outside)
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      "#{field} #{Enum.join(messages, ", ")}"
    end)
    |> Enum.join("; ")
  end
end
