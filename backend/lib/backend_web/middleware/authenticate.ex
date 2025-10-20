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
