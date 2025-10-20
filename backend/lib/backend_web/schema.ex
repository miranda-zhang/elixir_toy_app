defmodule BackendWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import_types Absinthe.Type.Custom
  import_types BackendWeb.Schema.UserTypes
  import_types BackendWeb.Schema.QueryTypes
  import_types BackendWeb.Schema.MutationTypes

  node interface do
    resolve_type fn
      %{__struct__: Backend.Accounts.User}, _ -> :user
      _, _ -> nil
    end
  end

  query do
    import_fields :root_query
  end

  mutation do
    import_fields :user_mutations
  end

end
