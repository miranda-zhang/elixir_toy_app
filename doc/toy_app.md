
# Toy app: login function

A **full-stack web app** built with a **modern Elixir + React stack**, integrating **GraphQL with Absinthe + Relay**, and using **Vite** as the frontend bundler.

---

# 🧱 Overall Architecture

```
+-------------------+
|   React (Vite)    |  ←→  GraphQL API  ←→  |  Phoenix (Elixir)  |
|   Relay Client     |                      |  Absinthe + Ecto    |
+-------------------+                      +---------------------+
                                                ↓
                                         PostgreSQL Database
```

---

# ⚙️ Tech Roles

| Layer                   | Tool              | Purpose                                                                    |
| ----------------------- | ----------------- | -------------------------------------------------------------------------- |
| **Database**            | PostgreSQL        | Stores user accounts, sessions, etc.                                       |
| **ORM / Query Builder** | Ecto              | Connects Phoenix to Postgres; manages schemas, migrations, and queries.    |
| **Backend Framework**   | Phoenix           | Handles HTTP requests, plugs, and GraphQL endpoints.                       |
| **API Layer**           | Absinthe          | Implements GraphQL, Relay-compliant schema (nodes, edges, connections).    |
| **Frontend**            | React (with Vite) | User interface for login/signup and user features.                         |
| **GraphQL Client**      | Relay             | Queries and mutations following Relay spec; uses fragments and pagination. |

---

# Backend Setup
- [Backend Deployment (optional)](./backend/deployment.md)
- [Backend Setup](./backend/backend.md)
- [GraphQL API](./backend/graphql.md)
- [User registration APIs](./backend/user_registration_apis.md)
- [Login APIs](./backend/login_apis.md)
- [Add phone number API](./backend/add_phone_api.md)
- [Cross-Origin Resource Sharing](./backend/cors.md)
- [Add query "me" in backend](./backend/user_query_me.md)

---

# Usefull commands
To compile, start, deploy server
```bash
mix compile
mix phx.server run

```

#  Local Graphql Plaground Query 

http://localhost:4000/api/graphiql

```graphql
mutation {
  registerUser(email: "test@example.com", password: "123456") {
    id
    email
  }
}

mutation {
  loginUser(email: "test@example.com", password: "123456")
}
```

In the **HTTP Headers** tab, add:

```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN"
}
```

```graphql
mutation {
  addPhoneNumber(phoneNumber: "+61412345678") {
    id
    email
    phoneNumber
  }
}
```
# Live Backend Query Without Playground

👉 [https://elixir-toy-app-backend.onrender.com/api](https://elixir-toy-app-backend.onrender.com/api)
(Note: it may take about 10 seconds to wake up after inactivity.)

```bash
curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -d '{"query":"{ hello }"}'

curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { registerUser(email: \"test@example.com\", password: \"123456\") { id email } }"}'

curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -d '{"query":"mutation { loginUser(email: \"test@example.com\", password: \"123456\")}"}'

curl -X POST https://elixir-toy-app-backend.onrender.com/api \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImV4cCI6MTc2MDk0MTc2MCwiaWF0IjoxNzYwOTM0NTYwLCJpc3MiOiJKb2tlbiIsImp0aSI6IjMxbzFoOXA5b205YW81czA1NDAwMDQxMSIsIm5iZiI6MTc2MDkzNDU2MCwidXNlcl9pZCI6MX0.qtJZx2-Eo4GcAl5kdk9l1vOdJAXJ81UBlPevGNMdsfE" \
  -d '{"query": "mutation { addPhoneNumber(phoneNumber: \"+61412345678\") { id email phoneNumber } }"}'

```
