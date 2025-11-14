defmodule SertantaiControls.Safety.ProviderNetwork do
  @moduledoc """
  Graph structure representing relationships between providers.
  Used to calculate provider distance via shortest path algorithms.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("provider_networks")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :from_provider_id, :uuid do
      allow_nil?(false)
    end

    attribute :to_provider_id, :uuid do
      allow_nil?(false)
    end

    attribute :relationship_type, :string do
      description("Type of relationship between providers")
    end

    attribute :path_weight, :decimal do
      default(Decimal.new("1.0"))
      description("Weight for calculating shortest path (default 1.0)")
    end

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :from_provider, SertantaiControls.Safety.ControlProvider
    belongs_to :to_provider, SertantaiControls.Safety.ControlProvider
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :from_provider_id,
        :to_provider_id,
        :relationship_type,
        :path_weight,
        :organization_id
      ])
    end

    update :update do
      accept([:relationship_type, :path_weight])
    end
  end

  code_interface do
    define(:create)
    define(:read)
    define(:update)
    define(:destroy)
  end
end
