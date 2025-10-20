defmodule BackendWeb.Token do
  use Joken.Config

  # Optionally define default claims (like exp, iat, etc.)
  @impl true
  def token_config do
    default_claims(skip: [:aud, :iss])
  end
end
