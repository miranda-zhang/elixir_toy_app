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
