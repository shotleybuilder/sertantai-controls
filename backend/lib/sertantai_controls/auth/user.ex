defmodule SertantaiControls.Auth.User do
  @moduledoc """
  Read-only resource for users table owned by sertantai-auth.
  This app does not create, update, or delete users.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("users")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :string do
      allow_nil?(false)
    end

    attribute(:name, :string)

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :organization, SertantaiControls.Auth.Organization
  end

  actions do
    defaults([:read])

    read :by_id do
      argument(:id, :uuid, allow_nil?: false)
      get?(true)
      filter(expr(id == ^arg(:id)))
    end

    read :by_organization do
      argument(:organization_id, :uuid, allow_nil?: false)
      filter(expr(organization_id == ^arg(:organization_id)))
    end
  end

  code_interface do
    define(:read)
    define(:by_id, args: [:id])
    define(:by_organization, args: [:organization_id])
  end
end
