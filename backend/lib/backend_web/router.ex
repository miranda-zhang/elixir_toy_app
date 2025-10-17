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

    # GraphQL endpoint for app/clients
    # /api → your GraphQL endpoint for API calls
    # /api/graphiql → opens an interactive browser playground
    forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: BackendWeb.Schema,
    interface: :playground

    forward "/", Absinthe.Plug,
      schema: BackendWeb.Schema

    # GraphiQL IDE (only enabled in dev)
    if Mix.env() == :dev do
      forward "/graphiql",
        Absinthe.Plug.GraphiQL,
        schema: BackendWeb.Schema,
        interface: :simple
    end
  end

  # ============================
  # LiveDashboard + Mailbox (dev only)
  # ============================
  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:backend, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: BackendWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
