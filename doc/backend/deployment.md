# Deployment (optional)

## 🟢 **Render.com** 

https://render.com/docs/free

**✅ Great for full-stack apps (Phoenix + Postgres)**

**Pros**

* Free PostgreSQL database.
* Free web service tier.
* Auto-deploy from GitHub.
* SSL + custom domain.
* Easy environment variable config.

**Cons**

* Cold start (~10s on free plan).
* 750 free hours/month per service (sleeps after inactivity).

**Setup**

1. Push your code to GitHub.
2. In Render:

   * Create a “Web Service” (point to Phoenix repo).
   * Add “PostgreSQL” under “Databases”.
3. Set `DATABASE_URL` and `SECRET_KEY_BASE`.

**Docs:** [https://render.com/docs/deploy-phoenix](https://render.com/docs/deploy-phoenix)

## ⚙️ Render Deployment Lifecycle

Render’s deploy process for a web service happens in this order:

1. **Build Command** → compiles your app
2. **Pre-Deploy Command** → runs *before* the new version goes live
3. **Start Command** → starts your application process
4. (Optional) **Post-Deploy Command** → runs *after* the app is already running and serving traffic

---

### ✅ Recommended setup for Phoenix apps

Use the **Pre-Deploy Command** for migrations:

```bash
MIX_ENV=prod mix ecto.migrate
```

This ensures that:

* Migrations run **before** the new app version starts serving requests.
* You won’t get schema mismatches between your app and database.
* If the migration fails, the new deploy won’t go live — which is safer.

---

### 🔧 Example `render.yaml`

```yaml
services:
  - type: web
    name: phoenix-app
    env: elixir
    buildCommand: mix deps.get && mix assets.deploy && mix compile
    preDeployCommand: MIX_ENV=prod mix ecto.migrate
    startCommand: mix phx.server
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: mydb
          property: connectionString

databases:
  - name: mydb
```

---

### 💡 If You’re Using a Release

If you’ve configured a Phoenix **release** (which is common for production builds), you’ll instead need to call your migration script inside the release:

```bash
_build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate()"
```

And define this in `lib/my_app/release.ex`:

```elixir
defmodule MyApp.Release do
  @app :my_app
  def migrate do
    Application.load(@app)
    for repo <- Application.fetch_env!(@app, :ecto_repos) do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
```

Then your `render.yaml` would have:

```yaml
preDeployCommand: _build/prod/rel/my_app/bin/my_app eval "MyApp.Release.migrate()"
```

---
## Use an external client to test API

You can test your **deployed GraphQL endpoint** directly using a client.

### 1. Check your endpoint URL

Your deployed endpoint is usually something like:

```
https://your-app-name.onrender.com/api/graphql
```

(Depends on what you defined in `router.ex` — e.g. `"/api/graphql"` or `"/graphql"`.)

### 2. Use a client such as:

* [**Apollo Sandbox**](https://studio.apollographql.com/sandbox/explorer)
* [**Hoppscotch**](https://hoppscotch.io)
* [**Postman**](https://www.postman.com)
* [**curl**](https://curl.se)

`curl` example:
```bash
curl -X POST https://your-app-name.onrender.com/api/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ users { id name } }"}'
```

These tools let you explore, query, and test the API — just like the Playground.

---

## Other possible options
Only tried render.com, other options haven't been verified.
### 🟣 **Railway.app**

**✅ Good for early prototypes**

**Pros**

* Very fast setup.
* Free PostgreSQL plugin.
* Auto-deploy from GitHub.
* Deploy Phoenix, Node, or any Docker image.

**Cons**

* Free tier usage is limited (~$5 worth of compute/month).
* No custom domain unless you upgrade.

**Setup**

```bash
railway init
railway up
```

**Docs:** [https://docs.railway.app](https://docs.railway.app)

---

### 🟡 **Vercel (Frontend only)**

**✅ Best for your React/Vite app**

**Pros**

* 100% free for personal projects.
* Auto-deploy from GitHub.
* Fast global CDN.
* Automatic HTTPS and previews.

**Cons**

* Backend (Phoenix) can’t run here — static hosting only.
* You’ll need CORS configured on your Phoenix API.

**Setup**

```bash
npm run build
vercel deploy
```

**Docs:** [https://vercel.com/docs](https://vercel.com/docs)

---

### 🟠 **Supabase**

**✅ Postgres backend as a service**

**Pros**

* Free-tier PostgreSQL DB.
* Includes auth + storage + real-time features.
* Easy connection string for Ecto.
* Great for prototyping user systems.

**Cons**

* No custom compute (you still need to host Phoenix elsewhere).

**Setup**

* Create Supabase project → get `DATABASE_URL`.
* Plug into `config/prod.exs`.

**Docs:** [https://supabase.com/docs](https://supabase.com/docs)

---

### 🔵 **Netlify (Frontend only, like Vercel)**

**✅ Alternative if you prefer Git integration**

**Pros**

* Free static hosting for React/Vite builds.
* HTTPS and previews.
* Great CI/CD integration.

**Cons**

* No Phoenix backend support.

**Setup**

```bash
npm run build
netlify deploy --prod
```
