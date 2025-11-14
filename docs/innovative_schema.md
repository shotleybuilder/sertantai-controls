# Innovative Schema Design - Risk Control 2x2 Model
## Based on "A New Model of Risk Control"

---

## Executive Summary

This schema design implements a dynamic risk control tracking system based on the 2x2 model with two axes:
- **Time Since Last Touched**: User familiarity and monitoring opportunity
- **Provider Distance**: User ownership and control level

The system automatically classifies controls into four quadrants (Self, Specialist, Service, Strange) and applies quadrant-specific monitoring, notification, and verification strategies.

---

## Core Innovation: Dynamic Quadrant Classification

Unlike static risk registers, this system:
1. **Automatically tracks** when users interact with controls
2. **Dynamically reclassifies** controls as they move between quadrants
3. **Predicts failures** based on time-since-touched and provider distance metrics
4. **Routes workflows** differently based on current quadrant position
5. **Surfaces organizational traces** (maintenance requests, incidents, training records)

---

## The Four Quadrants

```
Provider Distance (Y-axis)
     ^
     │
Close│ ┌─────────────┬─────────────┐
     │ │    SELF     │ SPECIALIST  │
     │ │  Recent +   │ Distant +   │
     │ │    Close    │    Close    │
     │ │             │             │
     │ │ • PPE       │ • Special   │
     │ │ • Tools     │   Equipment │
     │ │ • Vehicles  │ • Confined  │
     │ │             │   Space     │
     │ ├─────────────┼─────────────┤
     │ │   SERVICE   │   STRANGE   │
     │ │  Recent +   │ Distant +   │
     │ │   Remote    │   Remote    │
     │ │             │             │
Remote │ • Facilities│ • Airport   │
     │ │ • Contracted│   Systems   │
     │ │   Services  │ • Vendor    │
     │ │             │   Equipment │
     │ └─────────────┴─────────────┘
     └────────────────────────────> Time Since Last Touched
              Recent        Distant
```

---

## Schema Overview

### Core Entities

1. **Control** - The risk control itself
2. **ControlInteraction** - Each time a user touches/uses a control
3. **ControlProvider** - Entity responsible for the control
4. **ProviderNetwork** - Relationship between providers (path length)
5. **QuadrantClassification** - Historical record of quadrant positions
6. **OrganizationalTrace** - Maintenance, incidents, training records
7. **VerificationStrategy** - Quadrant-specific monitoring rules
8. **CompetencyRecord** - User qualifications for specialist controls
9. **ServiceLevelAgreement** - SLAs for service controls
10. **RiskPrediction** - AI-driven failure predictions

### External Resources (Read-Only from sertantai-auth)

11. **User** - Read-only reference to users table
12. **Organization** - Read-only reference to organizations table

---

## Detailed Schema Design

### Read-Only Resources (from sertantai-auth)

These resources reference tables owned by the sertantai-auth application:

```elixir
defmodule SertantaiControls.Auth.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "users"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :string
    attribute :name, :string
    attribute :organization_id, :uuid
  end

  actions do
    # Read-only - no create, update, or destroy
    defaults [:read]
  end
end

defmodule SertantaiControls.Auth.Organization do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizations"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string
    attribute :slug, :string
  end

  relationships do
    has_many :users, SertantaiControls.Auth.User
  end

  actions do
    # Read-only - no create, update, or destroy
    defaults [:read]
  end
end
```

---

### 1. Control Resource

```elixir
defmodule SertantaiControls.Safety.Control do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql, AshJsonApi]

  postgres do
    table "controls"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    # Basic Info
    attribute :name, :string, allow_nil?: false
    attribute :description, :text
    attribute :control_type, :string  # "physical", "procedural", "technical"

    # 2x2 Model Core Metrics
    attribute :last_touched_at, :utc_datetime_usec
    attribute :last_touched_by_user_id, :uuid
    attribute :provider_distance, :decimal  # Calculated path length in provider network

    # Current Quadrant (derived, cached for performance)
    attribute :current_quadrant, :string do
      constraints one_of: ["self", "specialist", "service", "strange"]
    end

    # Functional Range (nominal parameter)
    attribute :functional_range, :string do
      constraints one_of: ["narrow", "wide"]
    end

    # Calculated Risk Metrics
    attribute :days_since_touched, :integer  # Calculated
    attribute :failure_probability, :decimal  # AI-driven prediction
    attribute :requires_refresher_training, :boolean, default: false

    # Provider Info
    attribute :primary_provider_id, :uuid, allow_nil?: false
    attribute :owned_by_user, :boolean, default: false  # Self vs External

    # Multi-tenancy
    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :organization, SertantaiControls.Auth.Organization
    belongs_to :primary_provider, SertantaiControls.Safety.ControlProvider

    has_many :interactions, SertantaiControls.Safety.ControlInteraction
    has_many :classifications, SertantaiControls.Safety.QuadrantClassification
    has_many :traces, SertantaiControls.Safety.OrganizationalTrace
    has_many :predictions, SertantaiControls.Safety.RiskPrediction
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :description, :control_type, :functional_range,
              :primary_provider_id, :owned_by_user, :organization_id]
    end

    # Custom action: Record user interaction
    update :touch do
      accept []
      argument :user_id, :uuid, allow_nil?: false

      change fn changeset, context ->
        changeset
        |> Ash.Changeset.force_change_attribute(:last_touched_at, DateTime.utc_now())
        |> Ash.Changeset.force_change_attribute(:last_touched_by_user_id,
             context.arguments.user_id)
      end

      # After touch, recalculate quadrant and create classification record
      change after_action(fn changeset, record ->
        # Recalculate quadrant based on current metrics
        new_quadrant = determine_quadrant(record.days_since_touched, record.provider_distance)

        if new_quadrant != record.current_quadrant do
          # Update control's quadrant
          record = Ash.Changeset.for_update(record, :update, %{current_quadrant: new_quadrant})
            |> Ash.update!()

          # Create classification history record
          SertantaiControls.Safety.QuadrantClassification
          |> Ash.Changeset.for_create(:create, %{
            control_id: record.id,
            quadrant: new_quadrant,
            time_since_touched_days: record.days_since_touched,
            provider_distance: record.provider_distance,
            reason: "touch_interaction",
            organization_id: record.organization_id
          })
          |> Ash.create!()
        end

        {:ok, record}
      end)
    end

    # Helper function for quadrant determination
    defp determine_quadrant(days_since_touched, provider_distance) do
      time_recent = days_since_touched < 30
      provider_close = provider_distance < 2.0

      case {time_recent, provider_close} do
        {true, true} -> "self"
        {false, true} -> "specialist"
        {true, false} -> "service"
        {false, false} -> "strange"
      end
    end

    # Read actions with quadrant filters
    read :by_quadrant do
      argument :quadrant, :string, allow_nil?: false
      filter expr(current_quadrant == ^arg(:quadrant))
    end

    read :requiring_attention do
      # Controls that haven't been touched in a while relative to their quadrant
      filter expr(
        (current_quadrant == "self" and days_since_touched > 30) or
        (current_quadrant == "specialist" and days_since_touched > 90) or
        (current_quadrant == "service" and days_since_touched > 7) or
        (current_quadrant == "strange" and days_since_touched > 180)
      )
    end
  end

  calculations do
    calculate :days_since_touched, :integer do
      calculation fn records, _context ->
        Enum.map(records, fn record ->
          if record.last_touched_at do
            DateTime.diff(DateTime.utc_now(), record.last_touched_at, :day)
          else
            nil
          end
        end)
      end
    end

    calculate :time_category, :string do
      calculation fn records, context ->
        # Load days_since_touched calculation first
        records = Ash.load!(records, [:days_since_touched], context)

        Enum.map(records, fn record ->
          if record.days_since_touched && record.days_since_touched < 30 do
            "recent"
          else
            "distant"
          end
        end)
      end
    end

    calculate :provider_category, :string do
      calculation fn records, _context ->
        Enum.map(records, fn record ->
          if record.provider_distance && record.provider_distance < 2.0 do
            "close"
          else
            "remote"
          end
        end)
      end
    end
  end

  # Policies for multi-tenancy
  policies do
    policy action_type(:read) do
      authorize_if expr(organization_id == ^actor(:org_id))
    end

    policy action_type([:create, :update, :destroy]) do
      authorize_if expr(organization_id == ^actor(:org_id))
    end
  end
end
```

### 2. Control Interaction Resource

```elixir
defmodule SertantaiControls.Safety.ControlInteraction do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "control_interactions"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :control_id, :uuid, allow_nil?: false
    attribute :user_id, :uuid, allow_nil?: false
    attribute :interaction_type, :string do
      constraints one_of: ["use", "inspect", "maintain", "test"]
    end

    attribute :duration_minutes, :integer
    attribute :notes, :text
    attribute :issues_found, :boolean, default: false

    # Capture pre and post quadrant for tracking movement
    attribute :quadrant_before, :string
    attribute :quadrant_after, :string

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
    belongs_to :user, SertantaiControls.Auth.User
  end

  actions do
    defaults [:read]

    create :create do
      accept [:control_id, :user_id, :interaction_type, :duration_minutes,
              :notes, :issues_found, :organization_id]

      # Automatically update the control's last_touched
      change after_action(fn changeset, record ->
        Ash.update!(
          Ash.get!(Control, record.control_id),
          action: :touch,
          arguments: %{user_id: record.user_id}
        )
        {:ok, record}
      end)
    end
  end
end
```

### 3. Control Provider Resource

```elixir
defmodule SertantaiControls.Safety.ControlProvider do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "control_providers"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false
    attribute :provider_type, :string do
      constraints one_of: ["internal", "contractor", "vendor", "user"]
    end

    attribute :contact_info, :map
    attribute :is_user_themselves, :boolean, default: false  # For "self" quadrant

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :organization, SertantaiControls.Auth.Organization
    has_many :controls, SertantaiControls.Safety.Control

    # Network relationships (graph)
    many_to_many :connected_to, __MODULE__ do
      through SertantaiControls.Safety.ProviderNetwork
      source_attribute_on_join_resource :from_provider_id
      destination_attribute_on_join_resource :to_provider_id
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end
```

### 4. Provider Network Resource (Graph Structure)

```elixir
defmodule SertantaiControls.Safety.ProviderNetwork do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "provider_networks"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :from_provider_id, :uuid, allow_nil?: false
    attribute :to_provider_id, :uuid, allow_nil?: false
    attribute :relationship_type, :string  # "employs", "contracts", "supplies"
    attribute :path_weight, :decimal, default: 1.0  # For calculating distances

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :from_provider, SertantaiControls.Safety.ControlProvider
    belongs_to :to_provider, SertantaiControls.Safety.ControlProvider
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end
```

### 5. Quadrant Classification (Historical Tracking)

```elixir
defmodule SertantaiControls.Safety.QuadrantClassification do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "quadrant_classifications"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :control_id, :uuid, allow_nil?: false

    attribute :quadrant, :string, allow_nil?: false do
      constraints one_of: ["self", "specialist", "service", "strange"]
    end

    attribute :time_since_touched_days, :integer
    attribute :provider_distance, :decimal

    attribute :classified_at, :utc_datetime_usec, default: &DateTime.utc_now/0
    attribute :reason, :string  # What triggered the reclassification

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
  end

  actions do
    defaults [:create, :read]
  end
end
```

### 6. Organizational Trace Resource

```elixir
defmodule SertantaiControls.Safety.OrganizationalTrace do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "organizational_traces"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :control_id, :uuid, allow_nil?: false
    attribute :trace_type, :string, allow_nil?: false do
      constraints one_of: [
        "maintenance_request",
        "incident_report",
        "time_off_request",
        "training_record",
        "inspection_log",
        "work_order"
      ]
    end

    attribute :description, :text
    attribute :recorded_by_user_id, :uuid
    attribute :recorded_at, :utc_datetime_usec, default: &DateTime.utc_now/0

    attribute :related_incident_id, :uuid
    attribute :severity, :string  # For incidents

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
    belongs_to :recorded_by, SertantaiControls.Auth.User
  end

  actions do
    defaults [:create, :read]

    read :by_trace_type do
      argument :trace_type, :string, allow_nil?: false
      filter expr(trace_type == ^arg(:trace_type))
    end
  end
end
```

### 7. Verification Strategy Resource

```elixir
defmodule SertantaiControls.Safety.VerificationStrategy do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "verification_strategies"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :quadrant, :string, allow_nil?: false do
      constraints one_of: ["self", "specialist", "service", "strange"]
    end

    attribute :strategy_name, :string, allow_nil?: false
    attribute :description, :text

    # Different strategies per quadrant
    attribute :verification_method, :string do
      constraints one_of: [
        "user_reporting",          # Self
        "toolbox_talk",            # Specialist
        "sla_monitoring",          # Service
        "proactive_sampling"       # Strange
      ]
    end

    attribute :frequency_days, :integer
    attribute :notification_days_before, :integer
    attribute :escalation_enabled, :boolean, default: false

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end
end
```

### 8. Competency Record (for Specialist Quadrant)

```elixir
defmodule SertantaiControls.Safety.CompetencyRecord do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "competency_records"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :user_id, :uuid, allow_nil?: false
    attribute :control_id, :uuid, allow_nil?: false

    attribute :competency_level, :string do
      constraints one_of: ["novice", "competent", "proficient", "expert"]
    end

    attribute :last_training_date, :date
    attribute :next_refresher_due, :date
    attribute :training_hours, :decimal

    attribute :certified_by, :string
    attribute :certification_expires, :date

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :user, SertantaiControls.Auth.User
    belongs_to :control, SertantaiControls.Safety.Control
  end

  actions do
    defaults [:create, :read, :update]

    read :expiring_soon do
      filter expr(next_refresher_due <= ^Date.add(Date.utc_today(), 30))
    end
  end
end
```

### 9. Service Level Agreement (for Service Quadrant)

```elixir
defmodule SertantaiControls.Safety.ServiceLevelAgreement do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "service_level_agreements"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :control_id, :uuid, allow_nil?: false
    attribute :provider_id, :uuid, allow_nil?: false

    attribute :service_name, :string, allow_nil?: false
    attribute :uptime_percentage, :decimal  # e.g., 99.9
    attribute :response_time_hours, :decimal
    attribute :resolution_time_hours, :decimal

    attribute :start_date, :date, allow_nil?: false
    attribute :end_date, :date

    attribute :performance_current, :decimal  # Current performance vs SLA
    attribute :breaches_count, :integer, default: 0

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
    belongs_to :provider, SertantaiControls.Safety.ControlProvider
  end

  actions do
    defaults [:create, :read, :update]

    read :breached do
      filter expr(performance_current < uptime_percentage)
    end
  end
end
```

### 10. Risk Prediction (AI-driven)

```elixir
defmodule SertantaiControls.Safety.RiskPrediction do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "risk_predictions"
    repo SertantaiControls.Repo
  end

  attributes do
    uuid_primary_key :id

    attribute :control_id, :uuid, allow_nil?: false

    # Input features for ML model
    attribute :days_since_touched, :integer
    attribute :provider_distance, :decimal
    attribute :quadrant, :string
    attribute :functional_range, :string
    attribute :historical_incident_count, :integer
    attribute :trace_count_last_90_days, :integer

    # Prediction outputs
    attribute :failure_probability, :decimal  # 0.0 - 1.0
    attribute :predicted_failure_date, :date
    attribute :confidence_score, :decimal

    attribute :model_version, :string
    attribute :predicted_at, :utc_datetime_usec, default: &DateTime.utc_now/0

    attribute :organization_id, :uuid, allow_nil?: false

    timestamps()
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
  end

  actions do
    defaults [:create, :read]

    read :high_risk do
      filter expr(failure_probability > 0.7)
    end
  end
end
```

---

## Innovation Features

### 1. Automatic Quadrant Movement Tracking

The system continuously tracks:
- When controls move from Self → Specialist (e.g., user stops using personal equipment)
- When Service controls become Strange (provider changes, distance increases)
- When Specialist controls need refresher training (artificial time reduction)

### 2. Quadrant-Specific Workflows

```
Self Quadrant:
  ├─ Detect organizational traces (maintenance requests)
  ├─ Prompt for informal check-ins
  └─ Low-frequency formal inspections

Specialist Quadrant:
  ├─ Schedule toolbox talks
  ├─ Track competency expiration
  └─ Automatic refresher reminders

Service Quadrant:
  ├─ Monitor SLA performance
  ├─ Require provider feedback
  └─ Transparent reporting dashboards

Strange Quadrant:
  ├─ Proactive sampling inspections
  ├─ Secondary/tertiary verification
  └─ High-frequency audits
```

### 3. Provider Network Visualization

Calculate real provider distance using graph algorithms:
```sql
-- Dijkstra's shortest path in PostgreSQL
WITH RECURSIVE path AS (
  SELECT from_provider_id, to_provider_id, path_weight,
         ARRAY[from_provider_id] as path
  FROM provider_networks
  WHERE from_provider_id = :user_provider_id

  UNION ALL

  SELECT pn.from_provider_id, pn.to_provider_id,
         p.path_weight + pn.path_weight,
         p.path || pn.from_provider_id
  FROM provider_networks pn
  JOIN path p ON pn.from_provider_id = p.to_provider_id
  WHERE NOT pn.from_provider_id = ANY(p.path)
)
SELECT MIN(path_weight) as provider_distance
FROM path
WHERE to_provider_id = :control_provider_id;
```

### 4. Predictive Risk Scoring

Machine learning model that considers:
- Time decay function (exponential for Self, linear for Strange)
- Provider distance weighting
- Historical incident patterns
- Organizational trace patterns
- Functional range impact

### 5. Smart Notifications

Different notification strategies per quadrant:
- **Self**: Gentle reminders, detect anomalies in organizational traces
- **Specialist**: Training expiration alerts, toolbox talk schedules
- **Service**: SLA breach warnings, provider performance reports
- **Strange**: Mandatory audit reminders, verification checkpoints

---

## Domain Registration

All resources must be registered in the Ash Domain:

```elixir
defmodule SertantaiControls.Api do
  use Ash.Domain

  resources do
    # Auth (read-only from sertantai-auth)
    resource SertantaiControls.Auth.User
    resource SertantaiControls.Auth.Organization

    # Safety domain
    resource SertantaiControls.Safety.Control
    resource SertantaiControls.Safety.ControlInteraction
    resource SertantaiControls.Safety.ControlProvider
    resource SertantaiControls.Safety.ProviderNetwork
    resource SertantaiControls.Safety.QuadrantClassification
    resource SertantaiControls.Safety.OrganizationalTrace
    resource SertantaiControls.Safety.VerificationStrategy
    resource SertantaiControls.Safety.CompetencyRecord
    resource SertantaiControls.Safety.ServiceLevelAgreement
    resource SertantaiControls.Safety.RiskPrediction
  end
end
```

---

## Database Migrations

### Initial Migration

```elixir
defmodule SertantaiControls.Repo.Migrations.CreateRiskControlSchema do
  use Ecto.Migration

  def change do
    # Enable PostGIS for spatial queries if needed later
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    # Create tables
    create table(:control_providers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :provider_type, :string, null: false
      add :contact_info, :map
      add :is_user_themselves, :boolean, default: false
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:controls, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :control_type, :string
      add :last_touched_at, :utc_datetime_usec
      add :last_touched_by_user_id, :uuid
      add :provider_distance, :decimal
      add :current_quadrant, :string
      add :functional_range, :string
      add :days_since_touched, :integer
      add :failure_probability, :decimal
      add :requires_refresher_training, :boolean, default: false
      add :primary_provider_id, references(:control_providers, type: :uuid), null: false
      add :owned_by_user, :boolean, default: false
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:provider_networks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :from_provider_id, references(:control_providers, type: :uuid), null: false
      add :to_provider_id, references(:control_providers, type: :uuid), null: false
      add :relationship_type, :string
      add :path_weight, :decimal, default: 1.0
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:control_interactions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :control_id, references(:controls, type: :uuid), null: false
      add :user_id, references(:users, type: :uuid), null: false
      add :interaction_type, :string
      add :duration_minutes, :integer
      add :notes, :text
      add :issues_found, :boolean, default: false
      add :quadrant_before, :string
      add :quadrant_after, :string
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:quadrant_classifications, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :control_id, references(:controls, type: :uuid), null: false
      add :quadrant, :string, null: false
      add :time_since_touched_days, :integer
      add :provider_distance, :decimal
      add :classified_at, :utc_datetime_usec
      add :reason, :string
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    # Create indexes
    create index(:controls, [:organization_id])
    create index(:controls, [:current_quadrant])
    create index(:controls, [:last_touched_at])
    create index(:controls, [:primary_provider_id])
    create index(:control_interactions, [:control_id])
    create index(:control_interactions, [:user_id])
    create index(:quadrant_classifications, [:control_id])

    # Composite indexes for common queries
    create index(:controls, [:organization_id, :current_quadrant])
    create index(:controls, [:organization_id, :days_since_touched])

    # Additional tables for complete schema
    create table(:organizational_traces, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :control_id, references(:controls, type: :uuid), null: false
      add :trace_type, :string, null: false
      add :description, :text
      add :recorded_by_user_id, :uuid
      add :recorded_at, :utc_datetime_usec
      add :related_incident_id, :uuid
      add :severity, :string
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:verification_strategies, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :quadrant, :string, null: false
      add :strategy_name, :string, null: false
      add :description, :text
      add :verification_method, :string
      add :frequency_days, :integer
      add :notification_days_before, :integer
      add :escalation_enabled, :boolean, default: false
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:competency_records, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid), null: false
      add :control_id, references(:controls, type: :uuid), null: false
      add :competency_level, :string
      add :last_training_date, :date
      add :next_refresher_due, :date
      add :training_hours, :decimal
      add :certified_by, :string
      add :certification_expires, :date
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:service_level_agreements, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :control_id, references(:controls, type: :uuid), null: false
      add :provider_id, references(:control_providers, type: :uuid), null: false
      add :service_name, :string, null: false
      add :uptime_percentage, :decimal
      add :response_time_hours, :decimal
      add :resolution_time_hours, :decimal
      add :start_date, :date, null: false
      add :end_date, :date
      add :performance_current, :decimal
      add :breaches_count, :integer, default: 0
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    create table(:risk_predictions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :control_id, references(:controls, type: :uuid), null: false
      add :days_since_touched, :integer
      add :provider_distance, :decimal
      add :quadrant, :string
      add :functional_range, :string
      add :historical_incident_count, :integer
      add :trace_count_last_90_days, :integer
      add :failure_probability, :decimal
      add :predicted_failure_date, :date
      add :confidence_score, :decimal
      add :model_version, :string
      add :predicted_at, :utc_datetime_usec
      add :organization_id, references(:organizations, type: :uuid), null: false

      timestamps()
    end

    # Additional indexes
    create index(:organizational_traces, [:control_id])
    create index(:organizational_traces, [:trace_type])
    create index(:competency_records, [:user_id])
    create index(:competency_records, [:control_id])
    create index(:competency_records, [:next_refresher_due])
    create index(:service_level_agreements, [:control_id])
    create index(:service_level_agreements, [:provider_id])
    create index(:risk_predictions, [:control_id])
    create index(:risk_predictions, [:failure_probability])
  end
end
```

---

## API Endpoints

### GraphQL Schema

```graphql
type Control {
  id: ID!
  name: String!
  description: String
  currentQuadrant: Quadrant!
  daysSinceTouched: Int!
  providerDistance: Float!
  failureProbability: Float

  # Relationships
  provider: ControlProvider!
  interactions: [ControlInteraction!]!
  classifications: [QuadrantClassification!]!
  traces: [OrganizationalTrace!]!
  predictions: [RiskPrediction!]!
}

enum Quadrant {
  SELF
  SPECIALIST
  SERVICE
  STRANGE
}

type Query {
  controls(quadrant: Quadrant, organizationId: ID!): [Control!]!
  controlsRequiringAttention(organizationId: ID!): [Control!]!
  controlsByTimeDistance(
    organizationId: ID!,
    timeCategory: TimeCategory!,
    providerCategory: ProviderCategory!
  ): [Control!]!
}

type Mutation {
  touchControl(controlId: ID!, userId: ID!): Control!
  createInteraction(input: InteractionInput!): ControlInteraction!
  reclassifyControl(controlId: ID!): Control!
}
```

---

## Dashboard Visualizations

### 1. Quadrant Matrix View
```
Interactive 2x2 grid showing all controls positioned by:
- X: Days since last touched
- Y: Provider distance
Color-coded by failure probability
```

### 2. Movement Flow Diagram
```
Sankey diagram showing control movement between quadrants over time
Helps identify patterns (e.g., specialist controls becoming strange)
```

### 3. Provider Network Graph
```
Interactive network visualization showing:
- Provider nodes
- Relationship edges
- Path length calculations
- Control assignments
```

### 4. Attention Dashboard
```
Prioritized list of controls requiring action:
- Self: >30 days untouched
- Specialist: Training expiring
- Service: SLA breaches
- Strange: Overdue audits
```

---

## ElectricSQL Shape Exposure Strategy

Not all tables should be synced to the client. Here's the recommended exposure:

### ✅ Sync to Client (via ElectricSQL)
- `controls` - Core data, frequently accessed
- `control_interactions` - User activity tracking
- `control_providers` - Reference data
- `quadrant_classifications` - Historical context
- `competency_records` - User qualifications
- `organizational_traces` - Incident/maintenance records

### ⚠️ Backend-Only (No ElectricSQL exposure)
- `provider_networks` - Graph structure (complex queries)
- `verification_strategies` - Configuration data
- `service_level_agreements` - Sensitive contract terms
- `risk_predictions` - ML model outputs (backend-computed)

### 📊 Aggregated Sync
- For risk_predictions: Sync only the latest prediction per control, not full history

---

## ElectricSQL Sync Strategy

```typescript
// Frontend: TanStack DB Collections

import { createDb } from '@tanstack/db'

const db = createDb({
  collections: {
    controls: {
      fields: {
        id: 'string',
        name: 'string',
        currentQuadrant: 'string',
        daysSinceTouched: 'number',
        providerDistance: 'number',
        failureProbability: 'number',
        organizationId: 'string',
      },
      primaryKey: 'id',
    },

    interactions: {
      fields: {
        id: 'string',
        controlId: 'string',
        userId: 'string',
        interactionType: 'string',
        recordedAt: 'datetime',
      },
      primaryKey: 'id',
    },
  },
})

// Electric Shape Sync (org-scoped)
const controlsShape = await electric.sync({
  shape: {
    table: 'controls',
    where: `organization_id = '${orgId}'`,
  },
  collection: db.collections.controls,
})

// Live Query: Controls by Quadrant
const selfControls = db.collections.controls
  .query()
  .where('currentQuadrant', '=', 'self')
  .where('organizationId', '=', orgId)
  .live()

// Reactive computation: Attention Required
const attentionRequired = computed(() => {
  return db.collections.controls
    .query()
    .where('organizationId', '=', orgId)
    .filter(control => {
      if (control.currentQuadrant === 'self' && control.daysSinceTouched > 30) return true
      if (control.currentQuadrant === 'specialist' && control.daysSinceTouched > 90) return true
      if (control.currentQuadrant === 'service' && control.daysSinceTouched > 7) return true
      if (control.currentQuadrant === 'strange' && control.daysSinceTouched > 180) return true
      return false
    })
})
```

---

## Implementation Roadmap

### Phase 1: Core Schema (Week 1-2)
- [ ] Create Control, ControlProvider, ControlInteraction resources
- [ ] Implement basic quadrant calculation
- [ ] Set up multi-tenancy with org_id filtering
- [ ] Create migrations and seed data

### Phase 2: Dynamic Classification (Week 3-4)
- [ ] QuadrantClassification historical tracking
- [ ] Automatic reclassification on touch
- [ ] Provider network graph structure
- [ ] Path length calculation

### Phase 3: Organizational Traces (Week 5)
- [ ] OrganizationalTrace resource
- [ ] Integration with maintenance systems
- [ ] Incident reporting linkage

### Phase 4: Quadrant-Specific Features (Week 6-7)
- [ ] CompetencyRecord for Specialist
- [ ] ServiceLevelAgreement for Service
- [ ] VerificationStrategy per quadrant
- [ ] Smart notification system

### Phase 5: Predictive Analytics (Week 8-9)
- [ ] RiskPrediction ML model
- [ ] Failure probability scoring
- [ ] Attention dashboard

### Phase 6: Frontend Integration (Week 10-12)
- [ ] TanStack DB setup
- [ ] ElectricSQL sync
- [ ] Quadrant matrix visualization
- [ ] Movement tracking UI

---

## Success Metrics

1. **Accuracy**: Quadrant classification matches reality >95%
2. **Prediction**: Failure predictions >80% accuracy 30 days out
3. **Adoption**: Users interact with controls regularly (tracked)
4. **Safety**: Reduction in incidents from controls moving to Strange quadrant
5. **Efficiency**: Time-to-detect control degradation <7 days

---

## References

- Original Model: https://hsetp.wordpress.com/2021/05/05/a-new-model-of-risk-control/
- Ash Framework: https://ash-hq.org/
- ElectricSQL: https://electric-sql.com/
- TanStack DB: https://tanstack.com/db/
