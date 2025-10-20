defmodule BackendWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:user) do
    field :name, :string
    field :email, :string
    field :phone_number, :string
  end

  connection node_type: :user
end
