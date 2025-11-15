defmodule SertantaiControls.Safety.Control do
  @moduledoc """
  Core resource representing a risk control.
  Dynamically classified into quadrants based on time-since-touched and provider distance.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("controls")
    repo(SertantaiControls.Repo)
  end

  # Multi-tenancy: Automatically scope all queries by organization_id
  multitenancy do
    strategy(:attribute)
    attribute(:organization_id)
  end

  attributes do
    uuid_primary_key(:id)

    # Basic Info
    attribute :name, :string do
      allow_nil?(false)
    end

    attribute(:description, :string)

    attribute(:control_type, :string)

    # 2x2 Model Core Metrics
    attribute(:last_touched_at, :utc_datetime_usec)

    attribute(:last_touched_by_user_id, :uuid)

    attribute :provider_distance, :decimal do
      default(Decimal.new("0"))
      description("Calculated path length in provider network graph")
    end

    # Current Quadrant (derived, cached for performance)
    attribute :current_quadrant, :string do
      default("self")
    end

    # Functional Range (nominal parameter)
    attribute :functional_range, :string do
      default("wide")
    end

    # Calculated Risk Metrics
    attribute :failure_probability, :decimal do
      description("AI-driven prediction (0.0 - 1.0)")
    end

    attribute :requires_refresher_training, :boolean do
      default(false)
    end

    # Provider Info
    attribute :primary_provider_id, :uuid do
      allow_nil?(false)
    end

    attribute :owned_by_user, :boolean do
      default(false)
      description("Self vs External provider")
    end

    # Multi-tenancy
    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :organization, SertantaiControls.Auth.Organization
    belongs_to :primary_provider, SertantaiControls.Safety.ControlProvider

    has_many :interactions, SertantaiControls.Safety.ControlInteraction
    has_many :classifications, SertantaiControls.Safety.QuadrantClassification
    has_many :traces, SertantaiControls.Safety.OrganizationalTrace
    has_many :competency_records, SertantaiControls.Safety.CompetencyRecord
  end

  calculations do
    calculate(
      :days_since_touched,
      :integer,
      expr(fragment("COALESCE(EXTRACT(DAY FROM (NOW() - ?))::integer, 999)", last_touched_at))
    )

    calculate(
      :time_category,
      :string,
      expr(
        fragment(
          "CASE WHEN EXTRACT(DAY FROM (NOW() - ?)) < 30 THEN 'recent' ELSE 'distant' END",
          last_touched_at
        )
      )
    )

    calculate(
      :provider_category,
      :string,
      expr(fragment("CASE WHEN ? < 2.0 THEN 'close' ELSE 'remote' END", provider_distance))
    )
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :name,
        :description,
        :control_type,
        :functional_range,
        :primary_provider_id,
        :owned_by_user,
        :provider_distance,
        :organization_id
      ])

      change(fn changeset, _context ->
        # Set initial touch time
        Ash.Changeset.force_change_attribute(changeset, :last_touched_at, DateTime.utc_now())
      end)
    end

    update :update do
      accept([
        :name,
        :description,
        :control_type,
        :functional_range,
        :primary_provider_id,
        :owned_by_user,
        :provider_distance,
        :current_quadrant,
        :failure_probability,
        :requires_refresher_training,
        :last_touched_at,
        :last_touched_by_user_id
      ])
    end

    # Custom action: Record user interaction and recalculate quadrant
    update :touch do
      require_atomic?(false)
      accept([])
      argument(:user_id, :uuid, allow_nil?: false)

      change(fn changeset, context ->
        changeset
        |> Ash.Changeset.force_change_attribute(:last_touched_at, DateTime.utc_now())
        |> Ash.Changeset.force_change_attribute(
          :last_touched_by_user_id,
          context.arguments.user_id
        )
      end)

      change(after_action(&recalculate_quadrant_after_action/2))
    end

    # Read actions with quadrant filters
    read :by_quadrant do
      argument(:quadrant, :string, allow_nil?: false)
      argument(:organization_id, :uuid, allow_nil?: false)

      filter(
        expr(
          current_quadrant == ^arg(:quadrant) and
            organization_id == ^arg(:organization_id)
        )
      )
    end

    read :requiring_attention do
      argument(:organization_id, :uuid, allow_nil?: false)

      filter(
        expr(
          organization_id == ^arg(:organization_id) and
            ((current_quadrant == "self" and
                fragment("EXTRACT(DAY FROM (NOW() - ?))", last_touched_at) > 30) or
               (current_quadrant == "specialist" and
                  fragment("EXTRACT(DAY FROM (NOW() - ?))", last_touched_at) > 90) or
               (current_quadrant == "service" and
                  fragment("EXTRACT(DAY FROM (NOW() - ?))", last_touched_at) > 7) or
               (current_quadrant == "strange" and
                  fragment("EXTRACT(DAY FROM (NOW() - ?))", last_touched_at) > 180))
        )
      )
    end
  end

  code_interface do
    define(:create)
    define(:read)
    define(:update)
    define(:destroy)
    define(:touch, args: [:user_id])
    define(:by_quadrant, args: [:quadrant, :organization_id])
    define(:requiring_attention, args: [:organization_id])
  end

  # Helper function for quadrant determination
  defp determine_quadrant(days_since_touched, provider_distance) do
    time_recent = days_since_touched < 30
    provider_close = Decimal.compare(provider_distance, Decimal.new("2.0")) == :lt

    case {time_recent, provider_close} do
      {true, true} -> "self"
      {false, true} -> "specialist"
      {true, false} -> "service"
      {false, false} -> "strange"
    end
  end

  defp recalculate_quadrant_after_action(_changeset, record) do
    # Calculate days since touched
    days_since_touched =
      if record.last_touched_at do
        DateTime.diff(DateTime.utc_now(), record.last_touched_at, :day)
      else
        999
      end

    # Determine new quadrant
    new_quadrant = determine_quadrant(days_since_touched, record.provider_distance)

    if new_quadrant != record.current_quadrant do
      # Update control's quadrant
      record =
        record
        |> Ash.Changeset.for_update(:update, %{current_quadrant: new_quadrant})
        |> Ash.update!()

      # Create classification history record
      SertantaiControls.Safety.QuadrantClassification
      |> Ash.Changeset.for_create(:create, %{
        control_id: record.id,
        quadrant: new_quadrant,
        time_since_touched_days: days_since_touched,
        provider_distance: record.provider_distance,
        reason: "touch_interaction",
        organization_id: record.organization_id
      })
      |> Ash.create!()
    end

    {:ok, record}
  end
end
