defmodule SertantaiControls.Safety.CompetencyRecord do
  @moduledoc """
  Tracks user competency for specialist controls.
  Includes training dates, certification, and refresher requirements.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("competency_records")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :user_id, :uuid do
      allow_nil?(false)
    end

    attribute :control_id, :uuid do
      allow_nil?(false)
    end

    attribute :competency_level, :string do
      default("novice")
    end

    attribute(:last_training_date, :date)

    attribute :next_refresher_due, :date do
      description("When refresher training is required")
    end

    attribute :training_hours, :decimal do
      default(Decimal.new("0"))
    end

    attribute :certified_by, :string do
      description("Name or ID of certifying authority")
    end

    attribute(:certification_expires, :date)

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :user, SertantaiControls.Auth.User
    belongs_to :control, SertantaiControls.Safety.Control
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :user_id,
        :control_id,
        :competency_level,
        :last_training_date,
        :next_refresher_due,
        :training_hours,
        :certified_by,
        :certification_expires,
        :organization_id
      ])
    end

    update :update do
      accept([
        :competency_level,
        :last_training_date,
        :next_refresher_due,
        :training_hours,
        :certified_by,
        :certification_expires
      ])
    end

    read :by_user do
      argument(:user_id, :uuid, allow_nil?: false)
      filter(expr(user_id == ^arg(:user_id)))
    end

    read :by_control do
      argument(:control_id, :uuid, allow_nil?: false)
      filter(expr(control_id == ^arg(:control_id)))
    end

    read :expiring_soon do
      argument(:organization_id, :uuid, allow_nil?: false)
      argument(:days_ahead, :integer, default: 30)

      filter(
        expr(
          organization_id == ^arg(:organization_id) and
            next_refresher_due <= fragment("CURRENT_DATE + INTERVAL '? days'", ^arg(:days_ahead))
        )
      )
    end
  end

  code_interface do
    define(:create)
    define(:read)
    define(:update)
    define(:destroy)
    define(:by_user, args: [:user_id])
    define(:by_control, args: [:control_id])
    define(:expiring_soon, args: [:organization_id, {:optional, :days_ahead}])
  end
end
