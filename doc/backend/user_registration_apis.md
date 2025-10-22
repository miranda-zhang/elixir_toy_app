
# 🧩 User registration APIs

## Add dependencies

In `mix.exs`:

```elixir
defp deps do
  [
    {:bcrypt_elixir, "~> 3.0"},
    {:joken, "~> 2.6"}
  ]
end
```

Then:

```bash
mix deps.get
```

---

## Create User schema (Ecto)

`lib/backend/accounts/user.ex`:

```elixir
defmodule Backend.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :hashed_password, :string
    field :password, :string, virtual: true

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    if password = get_change(changeset, :password) do
      change(changeset, hashed_password: Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end
end
```

### 👉 1. `Bcrypt`

[`bcrypt_elixir`](https://hexdocs.pm/bcrypt_elixir/readme.html) 

This is a module from the `bcrypt_elixir` package — a wrapper around the well-known **bcrypt algorithm**.

### 👉 2. `.hash_pwd_salt(password)`

This function:

* Takes a plain-text password, e.g. `"123456"`
* Generates a **unique random salt**
* Applies the **bcrypt hashing algorithm**
* Returns a **secure hash string** (safe to store in DB)

Example:

```elixir
iex> Bcrypt.hash_pwd_salt("123456")
"$2b$12$T.Wpo6R7tbskExCHqLzI/.PrXpkavJ8vwWe4r5q8rb7nL6SRtD0xu"
```

That result is **not reversible** — you can’t get `"123456"` back.

---

### 🧠 Why it’s important

When you store users, never store plain passwords.
You store **only the hash** like above.
Then, when the user logs in, you verify with:

```elixir
Bcrypt.verify_pass(entered_password, user.hashed_password)
```

If it matches, the user is authenticated.

---

So when you register:

1. It takes `password: "123456"`
2. Calls `hash_pwd_salt`
3. Stores only the hashed result in the DB.

---

### ⚠️ Common gotchas

| Problem                                     | Fix                                                                  |
| ------------------------------------------- | -------------------------------------------------------------------- |
| `undefined function Bcrypt.hash_pwd_salt/1` | Add `{:bcrypt_elixir, "~> 3.0"}` in `mix.exs` and run `mix deps.get` |
| Slow in dev                                 | Bcrypt is intentionally slow — it’s for security.                    |
| Need faster test mode                       | Use `Bcrypt.add_hash/2` with `log_rounds: 4` during tests.           |

-
---

## Add Accounts context

`lib/backend/accounts.ex`:

```elixir
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
end
```

---

## JWT helper

`lib/backend/auth/token.ex`:

```elixir
defmodule Backend.Auth.Token do
  use Joken.Config

  def generate(user) do
    extra_claims = %{"user_id" => user.id}
    generate_and_sign!(extra_claims)
  end
end
```

---

## Absinthe Mutations

`lib/backend_web/schema/mutation_types.ex`:

```elixir
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

```

---

## Integrate into your main schema

`lib/backend_web/schema.ex`:

```elixir
defmodule BackendWeb.Schema do
  use Absinthe.Schema

  import_types BackendWeb.Schema.UserTypes
  import_types BackendWeb.Schema.MutationTypes

  mutation do
    import_fields :user_mutations
  end
end
```

---

## Generate + run migration

If you haven’t yet, generate an Ecto migration:

```bash
mix ecto.gen.migration create_users
```

Then edit the generated file (in `priv/repo/migrations/xxxx_create_users.exs`) to look like:

```elixir
defmodule Backend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :hashed_password, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
```

Then run the migration:

```bash
mix ecto.migrate
```

---

## Test via GraphQL Playground
```bash
mix compile
mix phx.server
```

Visit:
👉 [`http://localhost:4000/api/graphql`](http://localhost:4000/api/graphql)

Register user

```graphql
mutation {
  registerUser(email: "test@example.com", password: "123456") {
    id
    email
  }
}
```

# Error message

Right now your resolver probably does something like this (in `mutation_types.ex`):

```elixir
case Accounts.register_user(email, password) do
  {:ok, user} -> {:ok, user}
  {:error, _changeset} -> {:error, "Registration failed"}
end
```

Let’s make that much more helpful by extracting and returning **actual validation errors** from the changeset — for example `"Email has already been taken"` instead of a generic message.

---

### 🧩 Step 1: Improve your changeset in `accounts/user.ex`

If you’re not already validating uniqueness of email, add this:

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:email, :password])
  |> validate_required([:email, :password])
  |> validate_format(:email, ~r/@/)
  |> unique_constraint(:email)
end
```

That `unique_constraint(:email)` ensures we’ll get a clean Ecto changeset error when someone reuses an existing email.

---

### 🧩 Step 2: Decode and expose error messages in your resolver

In your mutation resolver (`lib/backend_web/schema/mutation_types.ex`):

```elixir
defmodule BackendWeb.Schema.MutationTypes do
  use Absinthe.Schema.Notation
  alias Backend.Accounts

  object :mutation do
    field :register_user, type: :user do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve fn %{email: email, password: password}, _ ->
        case Accounts.register_user(email, password) do
          {:ok, user} ->
            {:ok, user}

          {:error, changeset} ->
            {:error, format_changeset_errors(changeset)}
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
```


---

### 🧩 Step 3: Example improved output

Now when you register an existing email:

```graphql
mutation {
  registerUser(email: "test@example.com", password: "123456") {
    id
    email
  }
}
```

You’ll get something like:

```json
{
  "data": {
    "registerUser": null
  },
  "errors": [
    {
      "locations": [
        {
          "column": 3,
          "line": 2
        }
      ],
      "message": "email has already been taken",
      "path": [
        "registerUser"
      ]
    }
  ]
}
```

---

### ✅ Optional enhancement

If you want even more structured errors (for client-side validation), you could return a **custom error type** in your schema instead of a simple string, e.g.:

```elixir
union :register_user_result do
  types [:user, :error]
  resolve_type fn
    %{id: _}, _ -> :user
    %{message: _}, _ -> :error
  end
end
```

…but for now, the improved `format_changeset_errors/1` approach gives clear messages with minimal complexity.
