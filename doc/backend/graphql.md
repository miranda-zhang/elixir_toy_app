
# GraphQL API
Make your Phoenix app a **GraphQL API backend** that follows the **Relay spec** (with nodes, connections, etc.) using **Absinthe** 🚀

Let’s add a **minimal, working Absinthe + Relay GraphQL schema setup** for your `elixir_toy_app` backend.
This version will give you:

* `/graphql` endpoint (for API requests)
* `/graphiql` IDE (in dev)
* Basic Relay-compliant schema (`node`, `edges`, `pageInfo`)
* Example `User` type and resolver
* Clean structure so you can extend it later.

---

## 🧱 1. Add Dependencies

In your `backend/mix.exs`, add these to `deps()`:

```elixir
defp deps do
  [
    {:absinthe, "~> 1.7"},
    {:absinthe_relay, "~> 1.5"},
    {:absinthe_plug, "~> 1.5"}
  ]
end
```

Then run:

```bash
cd backend
mix deps.get
```

---

## 🗂️ 2. Router Setup

Edit `lib/backend_web/router.ex`:
```elixir
defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # ============================
  # GraphQL API
  # ============================
  scope "/api" do
    pipe_through :api

    # GraphiQL interactive playground (only for dev)
    # /api/graphiql → opens browser playground
    if Mix.env() == :dev do
      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: BackendWeb.Schema,
        interface: :playground,
        socket: BackendWeb.UserSocket,
        default_url: "/api"
    end

    # GraphQL endpoint for API calls
    # /api → GraphQL endpoint for frontend
    forward "/", Absinthe.Plug,
      schema: BackendWeb.Schema
  end

  # ============================
  # LiveDashboard + Mailbox (dev only)
  # ============================
  if Application.compile_env(:backend, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: BackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

```

---

## 🧩 3. GraphQL Schema Base

Create a new file:
`lib/backend_web/schema.ex`

```elixir
defmodule BackendWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import_types Absinthe.Type.Custom
  import_types BackendWeb.Schema.UserTypes
  import_types BackendWeb.Schema.QueryTypes

  node interface do
    resolve_type fn
      %{__struct__: Backend.Accounts.User}, _ -> :user
      _, _ -> nil
    end
  end

  query do
    import_fields :root_query
  end
end
```
Excellent — that’s your **root GraphQL schema module** for Absinthe (Elixir’s GraphQL library).
Let’s go line by line so you fully understand what each part does and why it’s written that way 👇

---

### `defmodule BackendWeb.Schema do`

Defines a module — this becomes your **main Absinthe schema**.
It tells Absinthe: “All my API’s types, queries, and resolvers live here.”

When Phoenix runs `/api/graphql`, Absinthe uses this schema to know what queries/mutations exist.

---

### `use Absinthe.Schema`

This macro turns your module into an **Absinthe schema definition**.
It:

* Imports macros like `query`, `mutation`, `subscription`, `field`, etc.
* Registers this module as a GraphQL schema so Absinthe can interpret it.

Essentially, this is the “GraphQL brain” of your backend.

---

### `use Absinthe.Relay.Schema, :modern`

This mixes in **Relay helpers and conventions**.
Relay (from Facebook) is a GraphQL spec for:

* Global object identification (`node` interface)
* Connections and pagination (`edges` / `pageInfo`)
* Cursor-based pagination instead of offset-based.

`:modern` is the newer style that uses a simpler syntax.

This adds macros like:

* `node interface`
* `connection`
* `node_field()`
* and global ID encoding/decoding helpers.

---

### `import_types Absinthe.Type.Custom`

Absinthe ships with `Absinthe.Type.Custom`, which provides built-in scalar types beyond standard GraphQL ones, like:

* `:datetime`
* `:decimal`
* `:uuid`
  So this import lets you use those types easily in your schema.

Example:

```elixir
field :created_at, :datetime
```

---

### `import_types BackendWeb.Schema.UserTypes`

This pulls in custom type definitions from another file/module —
you’ll define types like:

```elixir
node object(:user) do
  field :name, :string
end
```

in `lib/backend_web/schema/user_types.ex`.

That keeps your schema modular and clean.

---

### `query do ... end`

Defines the **root “Query” type** of your GraphQL API.
All read operations (queries) start here.

Inside this block you define:

* what queries clients can send
* what fields they can request
* and how to resolve them (using resolver functions)

---

### 🧠 Conceptually

| Concept          | Purpose                                                          |
| ---------------- | ---------------------------------------------------------------- |
| **Schema**       | Entry point of your API — defines what clients can query/mutate. |
| **Types**        | Define shape of data (User, Post, etc.).                         |
| **Resolvers**    | Functions that fetch the actual data.                            |
| **Relay**        | Adds conventions for pagination + global IDs.                    |
| **node_field()** | Lets clients fetch any object by a global ID.                    |
| **hello field**  | Test query proving the schema is working.                        |

---

### ⚙️ Flow Summary

When a request hits `/api/graphql`:

1. Phoenix forwards to `Absinthe.Plug`.
2. Absinthe loads your schema (`BackendWeb.Schema`).
3. It reads which `query` fields exist (`hello`, `node`, etc.).
4. It executes the resolver function for the requested field.
5. It serializes the result into a JSON GraphQL response.

---


## 👤 4. Example Relay Type — `User`

Create file:
`lib/backend_web/schema/user_types.ex`

```elixir
defmodule BackendWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:user) do
    field :name, :string
    field :email, :string
  end

  connection node_type: :user
end
```

A freshly generated Phoenix app (with `mix phx.new backend --no-html`) usually looks like:

```
lib/
  backend/
    application.ex
    repo.ex
  backend_web/
    endpoint.ex
    router.ex
    telemetry.ex
    ...
```

When you added Absinthe, you saw code like:

```elixir
import_types BackendWeb.Schema.UserTypes
```

But… there’s **no `schema/` folder by default**.
That’s because Phoenix doesn’t create GraphQL structure for you — **you create it manually.**

---

✅ Step-by-step: Add your `schema/` folder

Inside `lib/backend_web/`, create a folder:

```
lib/backend_web/schema/
```

Then add your schema modules there.

### 1. Root schema

Create a file:

```
lib/backend_web/schema.ex
```

Contents: see above

---

### 2. Add `UserTypes` (your first custom type module)

Create a file:

```
lib/backend_web/schema/user_types.ex
```

Contents:

```elixir
defmodule BackendWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:user) do
    field :name, :string
    field :email, :string
  end

  connection node_type: :user
end
```

---

Now your structure looks like this:

```
lib/backend_web/
  router.ex
  endpoint.ex
  ...
  schema/
    user_types.ex
  schema.ex
```

---

### ⚙️ Why this layout?

This pattern keeps your GraphQL API modular and scalable:

* `schema.ex` → root entry point (Query, Mutation, etc.)
* `schema/user_types.ex` → user-related objects
* later you can add `schema/post_types.ex`, `schema/comment_types.ex`, etc.

Then in `schema.ex`, you just:

```elixir
import_types BackendWeb.Schema.PostTypes
import_types BackendWeb.Schema.CommentTypes
```

---

### 🧠 Conceptually

* `backend_web/schema.ex` = like your **router** for GraphQL
* `backend_web/schema/*.ex` = like your **controllers/models** — defining each data domain

Absinthe just needs one entry point (`BackendWeb.Schema`), and from there it’ll import everything else.

---


## ⚙️ 5. Add query_types.ex in schema folder
> elixir_toy_app/backend/lib/backend_web/schema/user_types.ex

```elixir
defmodule BackendWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:user) do
    field :name, :string
    field :email, :string
  end

  connection node_type: :user
end
```
---

## 🧪 6. Run & Test

Start your Phoenix server:

```bash
mix phx.server
```

Then open:

👉 [http://localhost:4000/graphiql](http://localhost:4000/graphiql)

Run this test query:

```graphql
{
  hello
}
```

You should get:

```json
{
  "data": {
    "hello": "Hello from Absinthe!"
  }
}
```

---

## 🌐 7. Deploy Note (Render)

Because your `render.yaml` uses:

```yaml
buildCommand: mix deps.get && mix compile && mix ecto.migrate
startCommand: mix phx.server
```

→ This setup will **work on Render** out of the box — no extra config needed.

---

## ✅ Summary

| Component       | Path                                   | Purpose                          |
| --------------- | -------------------------------------- | -------------------------------- |
| `mix.exs`       | root of backend                        | adds Absinthe deps               |
| `router.ex`     | `lib/backend_web/router.ex`            | defines `/graphql` + `/graphiql` |
| `schema.ex`     | `lib/backend_web/schema.ex`            | root GraphQL schema              |
| `user_types.ex` | `lib/backend_web/schema/user_types.ex` | Relay-compliant `User` type      |
| `/graphql`      | API endpoint                           | POST requests                    |
| `/graphiql`     | dev IDE                                | try queries manually             |

---
