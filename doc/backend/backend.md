# 🧩 Backend Setup
### ⚙️ Step 1. Set Up a GitHub Repository

Create the project `elixir_toy_app` on the website, git clone it to local repo


### ⚙️ Step 2. Create the Phoenix App

From your terminal:

```bash
cd elixir_toy_app
mix phx.new backend --no-html --no-assets
```

When prompted:

```
Fetch and install dependencies? [Yn] Y
```

---

### ⚙️ Step 3. Verify Phoenix Works Locally

Inside the backend folder:

```bash
cd backend
mix ecto.create
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000) — you should see the Phoenix welcome page, seeing `Phoenix.Router.NoRouteError at GET /
no route found for GET / (BackendWeb.Router)` is normal.
If you see `invalid password` for Postgres, edit `config/dev.exs` to match your local DB credentials.

---
### ☁️ Step 4. Create free DB

Name it `elixir_toy_app_db`, both service and the database name can be the same.

Get the Internal Database URL, i.e.
```
postgresql://elixir_toy_app_db_user:wNgeEgRReZ03JKvEb19eqXnfyxSueQ7W@dpg-d3oq35emcj7s739gd9eg-a/elixir_toy_app_db
```

### ☁️ Step 5. Prepare for Render Deployment

We’ll configure the backend to deploy from `/backend` within the repo.

Create a file at the project root:

**`render.yaml`**

```yaml
services:
  - type: web
    name: elixir-toy-app-backend
    env: elixir
    rootDir: backend
    buildCommand: mix deps.get && mix compile && mix ecto.migrate
    startCommand: startCommand: mix phx.server
    plan: free
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: elixir_toy_app_db   # must exactly match your existing Render DB name
          property: connectionString
      - key: SECRET_KEY_BASE
        generateValue: true
```

👉 This tells Render:

* Your app lives in `/backend`
* It’s an Elixir project
* It needs a Postgres database
* It should auto-generate `SECRET_KEY_BASE`
* It will use a free Render plan

---

Commit and Push

```bash
git add render.yaml
git commit -m "Add Render config for backend"
git push
```

---

### ☁️ Step 6. Deploy on Render

1. Go to [https://render.com](https://render.com)
2. Click **“New +” → “Blueprint”**
3. Choose **“From a repo”**
4. Select your GitHub repo `elixir_toy_app`
5. Render reads the `render.yaml` automatically
6. Click **“Deploy Blueprint”**

Render will:

* Build your Phoenix app
* Provision a Postgres DB
* Run migrations
* Expose a public URL like:

  ```
  https://elixir-toy-app-backend.onrender.com
  ```

---

### ⚙️ Step 7. Verify Deployment

* Open the Render URL → you should see Phoenix’s error/debug page (the interactive “pretty printed” debug UI).
* Check the **Logs tab** for successful build + DB connection.

---

### ✅ Summary

| Step | Action                                      |
| ---- | ------------------------------------------- |
| 1    | `mix phx.new backend --no-html --no-assets` |
| 2    | `git init` in `elixir_toy_app/`             |
| 3    | Push to GitHub (`elixir_toy_app` repo)      |
| 4    | Add `render.yaml` at root                   |
| 5    | Deploy on Render → “Blueprint from GitHub”  |
| 6    | Get live Phoenix backend                    |

---
