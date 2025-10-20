defmodule BackendWeb.Plugs.Context do
  @behaviour Plug

  import Plug.Conn
  alias Backend.Auth.Token
  alias Backend.Repo
  alias Backend.Accounts.User

  def init(opts), do: opts

  def call(conn, _opts) do
    signer = Token.signer()

    context =
      with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
           {:ok, claims} <- Token.verify_and_validate(token, signer),
           %{"user_id" => user_id} <- claims,
           user when not is_nil(user) <- Repo.get(User, user_id) do
        # ✅ Now the context contains the full user struct
        %{current_user: user}
      else
        _ ->
          # 🚫 No valid token or user not found
          %{}
      end

    Absinthe.Plug.put_options(conn, context: context)
  end
end
