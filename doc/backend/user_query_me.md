# Add new query 

## 🧩 Step 1: Add a `me` field to your `:root_query`

You can safely add it inside your existing `BackendWeb.Schema.QueryTypes`:

```elixir
defmodule BackendWeb.Schema.QueryTypes do
  use Absinthe.Schema.Notation
  alias Absinthe.Relay.Node
  alias BackendWeb.Resolvers.UserResolver  # 👈 add this line

  object :root_query do
    field :node, :node do
      arg :id, non_null(:id)

      resolve fn %{id: global_id}, _ ->
        Node.from_global_id(global_id, BackendWeb.Schema)
      end
    end

    field :hello, :string do
      resolve(fn _, _, _ -> {:ok, "Hello from Absinthe!"} end)
    end

    # ✅ Add this new query
    field :me, :user do
      resolve(&UserResolver.me/3)
    end
  end
end
```

---

## 🧩 Step 2: Create the resolver module

Add this file:
`lib/backend_web/resolvers/user_resolver.ex`

```elixir
defmodule BackendWeb.Resolvers.UserResolver do
  # Return the current logged-in user if present in context
  def me(_parent, _args, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  # Handle unauthenticated case
  def me(_parent, _args, _resolution) do
    {:error, "Not authenticated"}
  end
end
```

---

## 🧠 Step 3: Restart the Phoenix server

Just to reload the new module:

```bash
mix phx.server
```

---

## 🧾 Step 4: Test in GraphiQL or frontend

In GraphiQL (or Postman, or your React app), send this query:

```graphql
query {
  me {
    id
    email
    phoneNumber
  }
}
```

with headers:

```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

If your token is valid, you’ll get:

```json
{
  "data": {
    "me": {
      "id": "1",
      "email": "user@example.com",
      "phoneNumber": "+61412345678"
    }
  }
}
```

If not logged in:

```json
{
  "errors": [{ "message": "Not authenticated" }]
}
```

---

✅ **Summary**

| File                                         | Change                           |
| -------------------------------------------- | -------------------------------- |
| `lib/backend_web/schema/query_types.ex`      | Add `field :me, :user`           |
| `lib/backend_web/resolvers/user_resolver.ex` | Add new file with resolver logic |
| `lib/backend_web/plugs/context.ex`           | Already perfect                  |

---

Would you like me to show the **Relay-compatible version** of this query too (for your React + Relay front end)? It’ll make it easier to load the user in your dashboard component.
