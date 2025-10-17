defmodule BackendWeb.Schema.QueryTypes do
  use Absinthe.Schema.Notation
  alias Absinthe.Relay.Node

  object :root_query do
    field :node, :node do
      arg :id, non_null(:id)

      resolve fn %{id: global_id}, _ ->
        Node.from_global_id(global_id, BackendWeb.Schema)
      end
    end

    field :hello, :string do
      resolve(fn _, _, _ -> {:ok, "Hello from Absinthe!"} end)
    end
  end
end
