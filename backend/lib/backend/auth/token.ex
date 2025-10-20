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
