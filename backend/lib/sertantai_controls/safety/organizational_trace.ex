defmodule SertantaiControls.Safety.OrganizationalTrace do
  @moduledoc """
  Captures organizational signals about controls:
  maintenance requests, incident reports, training records, inspections, etc.
  These traces help predict when controls need attention.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("organizational_traces")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :control_id, :uuid do
      allow_nil?(false)
    end

    attribute :trace_type, :string do
      allow_nil?(false)
    end

    attribute(:description, :string)

    attribute(:recorded_by_user_id, :uuid)

    attribute :recorded_at, :utc_datetime_usec do
      default(&DateTime.utc_now/0)
    end

    attribute :related_incident_id, :uuid do
      description("Optional link to incident management system")
    end

    attribute :severity, :string do
      description("For incidents and issues")
    end

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control

    belongs_to :recorded_by, SertantaiControls.Auth.User do
      source_attribute(:recorded_by_user_id)
      destination_attribute(:id)
    end
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :control_id,
        :trace_type,
        :description,
        :recorded_by_user_id,
        :related_incident_id,
        :severity,
        :organization_id,
        :recorded_at
      ])
    end

    read :by_trace_type do
      argument(:trace_type, :string, allow_nil?: false)
      argument(:organization_id, :uuid, allow_nil?: false)

      filter(
        expr(
          trace_type == ^arg(:trace_type) and
            organization_id == ^arg(:organization_id)
        )
      )
    end

    read :by_control do
      argument(:control_id, :uuid, allow_nil?: false)
      filter(expr(control_id == ^arg(:control_id)))
    end

    read :recent do
      argument(:organization_id, :uuid, allow_nil?: false)
      argument(:days, :integer, default: 90)

      filter(
        expr(
          organization_id == ^arg(:organization_id) and
            recorded_at > ago(^arg(:days), :day)
        )
      )
    end
  end

  code_interface do
    define(:create)
    define(:read)
    define(:by_trace_type, args: [:trace_type, :organization_id])
    define(:by_control, args: [:control_id])
    define(:recent, args: [:organization_id, {:optional, :days}])
  end
end
