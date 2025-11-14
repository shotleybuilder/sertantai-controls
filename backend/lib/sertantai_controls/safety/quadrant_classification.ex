defmodule SertantaiControls.Safety.QuadrantClassification do
  @moduledoc """
  Historical record of when controls move between quadrants.
  Provides audit trail and analytics on quadrant transitions.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("quadrant_classifications")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :control_id, :uuid do
      allow_nil?(false)
    end

    attribute :quadrant, :string do
      allow_nil?(false)
    end

    attribute :time_since_touched_days, :integer do
      description("Days since last touch at time of classification")
    end

    attribute :provider_distance, :decimal do
      description("Provider distance at time of classification")
    end

    attribute :classified_at, :utc_datetime_usec do
      default(&DateTime.utc_now/0)
    end

    attribute :reason, :string do
      description("What triggered the reclassification")
    end

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :control_id,
        :quadrant,
        :time_since_touched_days,
        :provider_distance,
        :reason,
        :organization_id,
        :classified_at
      ])
    end

    read :by_control do
      argument(:control_id, :uuid, allow_nil?: false)
      filter(expr(control_id == ^arg(:control_id)))
    end

    read :by_quadrant do
      argument(:quadrant, :string, allow_nil?: false)
      argument(:organization_id, :uuid, allow_nil?: false)

      filter(
        expr(
          quadrant == ^arg(:quadrant) and
            organization_id == ^arg(:organization_id)
        )
      )
    end
  end

  code_interface do
    define(:create)
    define(:read)
    define(:by_control, args: [:control_id])
    define(:by_quadrant, args: [:quadrant, :organization_id])
  end
end
