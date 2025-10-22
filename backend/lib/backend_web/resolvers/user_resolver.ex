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
