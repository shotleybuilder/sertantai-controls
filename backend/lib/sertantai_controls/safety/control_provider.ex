defmodule SertantaiControls.Safety.ControlProvider do
  @moduledoc """
  Entities responsible for risk controls (users, contractors, vendors, internal departments).
  Forms a network graph to calculate provider distance.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("control_providers")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
    end

    attribute :provider_type, :string do
      allow_nil?(false)
    end

    attribute(:contact_info, :map)

    attribute :is_user_themselves, :boolean do
      default(false)
      description("True if this represents the user themselves (for 'self' quadrant)")
    end

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :organization, SertantaiControls.Auth.Organization

    has_many :controls, SertantaiControls.Safety.Control do
      destination_attribute(:primary_provider_id)
    end

    many_to_many :connected_to, __MODULE__ do
      through(SertantaiControls.Safety.ProviderNetwork)
      source_attribute_on_join_resource(:from_provider_id)
      destination_attribute_on_join_resource(:to_provider_id)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([:name, :provider_type, :contact_info, :is_user_themselves, :organization_id])
    end

    update :update do
      accept([:name, :provider_type, :contact_info, :is_user_themselves])
    end
  end

  code_interface do
    define(:create)
    define(:read)
    define(:update)
    define(:destroy)
  end
end
