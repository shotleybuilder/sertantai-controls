defmodule SertantaiControls.Auth.Organization do
  @moduledoc """
  Read-only resource for organizations table owned by sertantai-auth.
  This app does not create, update, or delete organizations.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("organizations")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
    end

    attribute :slug, :string do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    has_many :users, SertantaiControls.Auth.User
  end

  actions do
    defaults([:read])

    read :by_id do
      argument(:id, :uuid, allow_nil?: false)
      get?(true)
      filter(expr(id == ^arg(:id)))
    end

    read :by_slug do
      argument(:slug, :string, allow_nil?: false)
      get?(true)
      filter(expr(slug == ^arg(:slug)))
    end
  end

  code_interface do
    define(:read)
    define(:by_id, args: [:id])
    define(:by_slug, args: [:slug])
  end
end
