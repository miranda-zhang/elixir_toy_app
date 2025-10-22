# Add Phone Number
You already have authentication (JWT via `BackendWeb.Token`) and a `registerUser` mutation, so now you want to add a **mutation like `addPhoneNumber`** that:

✅ Requires a valid JWT
✅ Adds or updates the user’s phone number in the DB

---

## 🧩 Add a field to your user schema

In `lib/backend/accounts/user.ex`:

```elixir
schema "users" do
  field :email, :string
  field :hashed_password, :string
  field :phone_number, :string

  timestamps()
end
```

Then generate and run a migration:

```bash
mix ecto.gen.migration add_phone_number_to_users
```

Inside the new migration file:

```elixir
def change do
  alter table(:users) do
    add :phone_number, :string
  end
end
```

Then run:

```bash
mix ecto.migrate
```

---

## 🧩 Create a context function

In `lib/backend/accounts.ex`:

```elixir
def update_phone_number(user_id, phone_number) do
  user = Repo.get!(User, user_id)

  user
  |> Ecto.Changeset.change(phone_number: phone_number)
  |> Repo.update()
end
```

---

## 🧩 Add Absinthe middleware to authenticate the JWT

Modify your router include the plug before:

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug BackendWeb.Plugs.Context
end
```

---

## Use a custom Plug to set the Absinthe context

### **1️⃣ Create a plug**

Create this file:
`lib/backend_web/plugs/context.ex`

```elixir
defmodule BackendWeb.Plugs.Context do
  @behaviour Plug

  import Plug.Conn
  alias Backend.Auth.Token
  alias Backend.Repo
  alias Backend.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    signer = Token.signer()

    context =
      with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
           {:ok, claims} <- Token.verify_and_validate(token, signer),
           %{"user_id" => user_id} <- claims,
           user when not is_nil(user) <- Repo.get(User, user_id) do
        # ✅ Now the context contains the full user struct
        # IO.inspect(claims, label: "JWT CLAIMS")
        %{current_user: user}
      else
        _ ->
          # 🚫 No valid token or user not found
          %{}
      end

    Absinthe.Plug.put_options(conn, context: context)
  end
end

```

---

### **2️⃣ Use that plug before forwarding to Absinthe**

In your `lib/backend_web/router.ex`:

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug BackendWeb.Plugs.Context  # ✅ do it here
end
```
---

## 🧩 Add the `addPhoneNumber` mutation

In `lib/backend_web/schema/mutation_types.ex`:

```elixir
mutation do
  field :add_phone_number, type: :user do
    arg :phone_number, non_null(:string)

    resolve fn %{phone_number: phone_number}, %{context: %{current_user: user}} ->
      case Backend.Accounts.update_phone_number(user.id, phone_number) do
        {:ok, updated_user} -> {:ok, updated_user}
        {:error, changeset} -> {:error, "Failed to update phone number"}
      end
    end
  end
end
```

---

## 🧠 How context work

When your `BackendWeb.Plugs.Context` sets:

```elixir
%{current_user: user_id}
```

every resolver in Absinthe will receive this context automatically.

You can then:

* Check if `context.current_user` exists.
* Fail gracefully if not.
* Otherwise continue with the resolver logic.

---

### ✅ 1️⃣ Create a helper middleware module

Create a middleware file for authentication checks:
`lib/backend_web/middleware/authenticate.ex`

```elixir
defmodule BackendWeb.Middleware.Authenticate do
  @behaviour Absinthe.Middleware

  def call(%{context: %{current_user: user_id}} = resolution, _config) when not is_nil(user_id) do
    resolution
  end

  def call(resolution, _config) do
    resolution
    |> Absinthe.Resolution.put_result({:error, "Unauthorized"})
  end
end
```

---

### ✅ 2️⃣ Use it in your schema

Let’s say your mutation looks like this:

```elixir
field :update_phone, type: :user do
  arg :phone_number, non_null(:string)

  middleware BackendWeb.Middleware.Authenticate  # 👈 Require auth
  resolve &Resolvers.User.update_phone/3
end
```

Now any request to `update_phone` without a valid JWT will return:

```json
{
  "errors": [
    { "message": "Unauthorized" }
  ]
}
```

---

### ✅ 4️⃣ (Optional) Apply globally for authenticated groups

If you have many authenticated fields, you can also **apply the middleware to a whole object**:

```elixir
object :protected_mutations do
  middleware BackendWeb.Middleware.Authenticate

  field :update_phone, type: :user do
    arg :phone_number, non_null(:string)
    resolve &Resolvers.User.update_phone/3
  end
end
```

---

### ✅ Summary

| Step                                                   | Purpose                                |
| ------------------------------------------------------ | -------------------------------------- |
| 🔧 `BackendWeb.Plugs.Context`                          | Extracts and verifies JWT from headers |
| 🧩 `BackendWeb.Middleware.Authenticate`                | Stops requests without `current_user`  |
| 🧠 `context.current_user`                              | Accessible inside all resolvers        |
| 🧱 Use `middleware BackendWeb.Middleware.Authenticate` | Protects specific or all fields        |

---

## Update Your `user` Object Type

Open your file (usually `lib/backend_web/schema/types/user_types.ex` or wherever you define the user object)
and modify it like this:

```elixir
object :user do
  field :id, :id
  field :email, :string
  field :phone_number, :string, name: "phoneNumber"
end
```

That tells Absinthe:

> The Elixir field is `phone_number`, but clients can query it as `phoneNumber`.

---

## Enable camelCase globally (recommended)

In your **router**, inside your GraphQL forward:

```elixir
forward "/api", Absinthe.Plug,
  schema: BackendWeb.Schema,
  json_codec: Jason,
  camelize: :lower
```

and for GraphiQL too:

```elixir
forward "/api/graphiql", Absinthe.Plug.GraphiQL,
  schema: BackendWeb.Schema,
  interface: :playground,
  socket: BackendWeb.UserSocket,
  default_url: "/api",
  json_codec: Jason,
  camelize: :lower
```

✅ **Result:**

* All output field names (`phone_number`) → `phoneNumber`
* All input argument names (`phoneNumber`) → automatically translated to snake_case internally

You don’t have to rename anything in your schema.

---

…and now you can do:

```graphql
mutation {
  addPhoneNumber(phoneNumber: "0412345678") {
    id
    phoneNumber
  }
}
```

instead of `phone_number`. 🎉

---

## 🧩 Test the mutation

In your GraphQL Playground (`/api/graphiql`):

```graphql
mutation {
  addPhoneNumber(phoneNumber: "+61412345678") {
    id
    email
    phoneNumber
  }
}
```

In the **HTTP Headers** tab, add:

```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```
