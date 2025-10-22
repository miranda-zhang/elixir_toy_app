
# Login

## Define a token module

You should have a module that defines your JWT logic.
Create (or edit) `lib/backend_web/token.ex`:

```elixir
defmodule BackendWeb.Token do
  use Joken.Config

  # Optionally define default claims (like exp, iat, etc.)
  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss])
  end
end
```

This automatically provides:

* `generate_and_sign/1`
* `verify_and_validate/1`
* A default HMAC signer (using `JOSE.JWS` with a secret key)

This module is a **Joken token configuration module**, and it’s basically where you define how your app *creates and validates* JWTs (JSON Web Tokens).

Let’s go line by line 👇

---

### 🔹 `defmodule BackendWeb.Token do`

Defines a new module for handling tokens — it’s a good convention to keep JWT logic separate from your user logic.

---

### 🔹 `use Joken.Config`

This line **imports default behavior from `Joken.Config`**, which provides a ready-made framework for:

* Signing tokens
* Validating claims
* Handling token expiry, issued-at timestamps, etc.

When you `use Joken.Config`, Joken automatically defines helper functions for you, such as:

* `generate_and_sign/2` and `generate_and_sign!/2`
* `verify_and_validate/2`
* `token_config/0` (you override this one to customize token claims)

---

### 🔹 `@impl true`

This means:

> “I’m overriding a callback defined by `Joken.Config`.”

Specifically, `Joken.Config` expects you to optionally implement `token_config/0` if you want to customize claims.

---

### 🔹 `def token_config do ... end`

This function defines **default claims** — things that every token should include or omit.

Joken has a helper called `default_claims/1`, which automatically includes these standard JWT fields:

| Claim | Meaning         |
| ----- | --------------- |
| `exp` | Expiration time |
| `iat` | Issued at time  |
| `nbf` | Not before time |
| `iss` | Issuer          |
| `aud` | Audience        |

By default, `default_claims/0` includes *all* of them — but here, you’re telling Joken to **skip `aud` and `iss`** (because your app doesn’t use those):

```elixir
default_claims(skip: [:aud, :iss])
```

That means your token will still include `exp`, `iat`, and `nbf` automatically.

---

### ✅ So what this module gives you

After defining this, you can call:

```elixir
# Create a signer
signer = Joken.Signer.create("HS256", "mysecret")

# Create a token with some custom data
{:ok, token, _claims} = BackendWeb.Token.generate_and_sign(%{"user_id" => 1}, signer)

# Later, verify and decode
{:ok, claims} = BackendWeb.Token.verify_and_validate(token, signer)
```

---

### 🧠 Summary

| Line                                 | Purpose                                                 |
| ------------------------------------ | ------------------------------------------------------- |
| `use Joken.Config`                   | Loads default Joken behavior                            |
| `@impl true`                         | Marks that we’re overriding a built-in callback         |
| `def token_config do ... end`        | Defines which default JWT claims to include/skip        |
| `default_claims(skip: [:aud, :iss])` | Skips issuer and audience claims, keeps expiration etc. |


---

## Add a secret key

Joken uses a **signer secret** under the hood.
You can define it in your config, use environment variable (better for prod):

```elixir
config :backend, jwt_secret: System.get_env("JWT_SECRET") || "dev_secret"
```

Then create an environment variable in your shell (for production):

```bash
export JWT_SECRET="super_secure_random_string"
```

Phoenix will read this automatically on boot.

---
## Generate a secret

* You can generate a stronger secret with:

  ```bash
  openssl rand -hex 32
  ```

* On Render or any other cloud host, you’ll set this in the **Environment Variables section**.


## Add the JWT secret permanently

Run this in your terminal:

```bash
echo 'export JWT_SECRET="super_secure_random_string"' >> ~/.bashrc
```

Then reload your shell so it takes effect:

```bash
source ~/.bashrc
```

Now you can confirm it’s set:

```bash
echo $JWT_SECRET
```

---

## Update token module

```elixir
defmodule Backend.Auth.Token do
  use Joken.Config

  def signer do
    secret = Application.fetch_env!(:backend, :jwt_secret)
    Joken.Signer.create("HS256", secret)
  end

  def generate(user) do
    extra_claims = %{"user_id" => user.id}
    generate_and_sign!(extra_claims, signer())
  end
end
```

---

## Restart and test

After updating config or code:

```bash
mix compile
mix phx.server
```

Then run your GraphQL login mutation:
```graphql
mutation {
  loginUser(email: "test@example.com", password: "123456")
}

```
it should return a valid JWT token like:

```json
{
  "data": {
    "loginUser": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImV4cCI6MTc2MDkyNjkwNCwiaWF0IjoxNzYwOTE5NzA0LCJpc3MiOiJKb2tlbiIsImp0aSI6IjMxbzBtOTFycW42MDl2cWQ3ODAwMDByMiIsIm5iZiI6MTc2MDkxOTcwNCwidXNlcl9pZCI6MX0.C5fLeqIrCGOofHlLs1IiIRmXXBRcA0Cpsa7H4EJQ1e4"
  }
}
```
