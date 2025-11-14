# Script for populating the database with synthetic risk control data
# Demonstrates the 2x2 model (Time Since Touched × Provider Distance)
#
# Run with: mix run priv/repo/seeds.exs

alias SertantaiControls.Auth.{Organization, User}

alias SertantaiControls.Safety.{
  ControlProvider,
  Control,
  ProviderNetwork,
  ControlInteraction,
  QuadrantClassification,
  OrganizationalTrace,
  CompetencyRecord
}

require Ash.Query

IO.puts("\n🌱 Seeding sertantai-controls database...")

# Clear existing data (in reverse dependency order)
IO.puts("Clearing existing data...")
Ash.bulk_destroy!(CompetencyRecord, :destroy, %{})
Ash.bulk_destroy!(OrganizationalTrace, :destroy, %{})
Ash.bulk_destroy!(QuadrantClassification, :destroy, %{})
Ash.bulk_destroy!(ControlInteraction, :destroy, %{})
Ash.bulk_destroy!(Control, :destroy, %{})
Ash.bulk_destroy!(ProviderNetwork, :destroy, %{})
Ash.bulk_destroy!(ControlProvider, :destroy, %{})
# Don't delete users/orgs (they're owned by sertantai-auth in production)

# ========================================
# 1. CREATE ORGANIZATION & USERS
# ========================================
IO.puts("\n📊 Creating organization and users...")

# These tables are owned by sertantai-auth but we need seed data for dev
# Using Ecto.Repo directly since these are read-only Ash resources
org_id_string = Ash.UUID.generate()
{:ok, org_id_binary} = Ecto.UUID.dump(org_id_string)
now = DateTime.utc_now() |> DateTime.truncate(:second)

{:ok, %Postgrex.Result{rows: [org_row]}} =
  Ecto.Adapters.SQL.query(
    SertantaiControls.Repo,
    "INSERT INTO organizations (id, name, slug, inserted_at, updated_at)
   VALUES ($1, $2, $3, $4, $5)
   ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name
   RETURNING *",
    [org_id_binary, "Acme Construction Ltd", "acme-construction", now, now]
  )

org = %{id: Enum.at(org_row, 0), name: Enum.at(org_row, 1), slug: Enum.at(org_row, 2)}

user_john_id_string = Ash.UUID.generate()
{:ok, user_john_id_binary} = Ecto.UUID.dump(user_john_id_string)

{:ok, %Postgrex.Result{rows: [john_row]}} =
  Ecto.Adapters.SQL.query(
    SertantaiControls.Repo,
    "INSERT INTO users (id, email, name, organization_id, inserted_at, updated_at)
   VALUES ($1, $2, $3, $4, $5, $6)
   ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email
   RETURNING *",
    [user_john_id_binary, "john.smith@acme.com", "John Smith", org_id_binary, now, now]
  )

user_john = %{id: Enum.at(john_row, 0)}

user_sarah_id_string = Ash.UUID.generate()
{:ok, user_sarah_id_binary} = Ecto.UUID.dump(user_sarah_id_string)

{:ok, %Postgrex.Result{rows: [sarah_row]}} =
  Ecto.Adapters.SQL.query(
    SertantaiControls.Repo,
    "INSERT INTO users (id, email, name, organization_id, inserted_at, updated_at)
   VALUES ($1, $2, $3, $4, $5, $6)
   ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email
   RETURNING *",
    [user_sarah_id_binary, "sarah.jones@acme.com", "Sarah Jones", org_id_binary, now, now]
  )

user_sarah = %{id: Enum.at(sarah_row, 0)}

user_mike_id_string = Ash.UUID.generate()
{:ok, user_mike_id_binary} = Ecto.UUID.dump(user_mike_id_string)

{:ok, %Postgrex.Result{rows: [mike_row]}} =
  Ecto.Adapters.SQL.query(
    SertantaiControls.Repo,
    "INSERT INTO users (id, email, name, organization_id, inserted_at, updated_at)
   VALUES ($1, $2, $3, $4, $5, $6)
   ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email
   RETURNING *",
    [user_mike_id_binary, "mike.chen@acme.com", "Mike Chen", org_id_binary, now, now]
  )

user_mike = %{id: Enum.at(mike_row, 0)}

IO.puts("✓ Created organization: #{org.name}")
IO.puts("✓ Created 3 users")

# ========================================
# 2. CREATE PROVIDERS & NETWORK
# ========================================
IO.puts("\n🏢 Creating providers and network...")

# Distance 0: User themselves
provider_john =
  ControlProvider
  |> Ash.Changeset.for_create(:create, %{
    name: "John Smith (self)",
    provider_type: "user",
    is_user_themselves: true,
    organization_id: org.id
  })
  |> Ash.create!()

provider_sarah =
  ControlProvider
  |> Ash.Changeset.for_create(:create, %{
    name: "Sarah Jones (self)",
    provider_type: "user",
    is_user_themselves: true,
    organization_id: org.id
  })
  |> Ash.create!()

# Distance 1: Internal department
provider_safety_dept =
  ControlProvider
  |> Ash.Changeset.for_create(:create, %{
    name: "Safety Department",
    provider_type: "internal",
    contact_info: %{"phone" => "555-1234", "email" => "safety@acme.com"},
    organization_id: org.id
  })
  |> Ash.create!()

# Distance 1-2: Contractor
provider_contractor =
  ControlProvider
  |> Ash.Changeset.for_create(:create, %{
    name: "EquipCare Services",
    provider_type: "contractor",
    contact_info: %{"phone" => "555-5678", "company" => "EquipCare Ltd"},
    organization_id: org.id
  })
  |> Ash.create!()

# Distance 3+: Remote vendor
provider_vendor =
  ControlProvider
  |> Ash.Changeset.for_create(:create, %{
    name: "GlobalSafe Industries",
    provider_type: "vendor",
    contact_info: %{"email" => "support@globalsafe.com", "country" => "Germany"},
    organization_id: org.id
  })
  |> Ash.create!()

# Create provider network (graph for distance calculation)
ProviderNetwork
|> Ash.Changeset.for_create(:create, %{
  from_provider_id: provider_john.id,
  to_provider_id: provider_safety_dept.id,
  relationship_type: "employs",
  path_weight: Decimal.new("1.0"),
  organization_id: org.id
})
|> Ash.create!()

ProviderNetwork
|> Ash.Changeset.for_create(:create, %{
  from_provider_id: provider_safety_dept.id,
  to_provider_id: provider_contractor.id,
  relationship_type: "contracts",
  path_weight: Decimal.new("1.5"),
  organization_id: org.id
})
|> Ash.create!()

ProviderNetwork
|> Ash.Changeset.for_create(:create, %{
  from_provider_id: provider_contractor.id,
  to_provider_id: provider_vendor.id,
  relationship_type: "supplies",
  path_weight: Decimal.new("2.0"),
  organization_id: org.id
})
|> Ash.create!()

IO.puts("✓ Created 5 providers with network relationships")

# ========================================
# 3. CREATE CONTROLS (ACROSS ALL QUADRANTS)
# ========================================
IO.puts("\n🎯 Creating controls across all quadrants...")

# SELF QUADRANT: Recent touch + Close provider
control_ppe =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Personal Protective Equipment (PPE)",
    description: "Hard hat, safety glasses, steel-toed boots",
    control_type: "physical",
    functional_range: "wide",
    primary_provider_id: provider_john.id,
    owned_by_user: true,
    provider_distance: Decimal.new("0.0"),
    organization_id: org.id
  })
  |> Ash.create!()

# Touch it recently (5 days ago)
control_ppe =
  control_ppe
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -5, :day),
    last_touched_by_user_id: user_john.id,
    current_quadrant: "self"
  })
  |> Ash.update!()

control_toolbox =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Personal Toolbox Lock",
    description: "Lockout/tagout for personal tools",
    control_type: "physical",
    functional_range: "narrow",
    primary_provider_id: provider_sarah.id,
    owned_by_user: true,
    provider_distance: Decimal.new("0.0"),
    organization_id: org.id
  })
  |> Ash.create!()

control_toolbox =
  control_toolbox
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -2, :day),
    last_touched_by_user_id: user_sarah.id,
    current_quadrant: "self"
  })
  |> Ash.update!()

# SPECIALIST QUADRANT: Distant touch + Close provider
control_confined_space =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Confined Space Entry Permit",
    description: "Special training and equipment required",
    control_type: "procedural",
    functional_range: "narrow",
    primary_provider_id: provider_safety_dept.id,
    provider_distance: Decimal.new("1.0"),
    organization_id: org.id
  })
  |> Ash.create!()

# Touch it 45 days ago (distant)
control_confined_space =
  control_confined_space
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -45, :day),
    last_touched_by_user_id: user_mike.id,
    current_quadrant: "specialist",
    requires_refresher_training: true
  })
  |> Ash.update!()

control_forklift =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Forklift Operation Certification",
    description: "Licensed forklift operation",
    control_type: "procedural",
    functional_range: "narrow",
    primary_provider_id: provider_safety_dept.id,
    provider_distance: Decimal.new("1.0"),
    organization_id: org.id
  })
  |> Ash.create!()

control_forklift =
  control_forklift
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -120, :day),
    last_touched_by_user_id: user_john.id,
    current_quadrant: "specialist",
    requires_refresher_training: true
  })
  |> Ash.update!()

# SERVICE QUADRANT: Recent touch + Remote provider
control_fire_system =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Fire Suppression System",
    description: "Automated sprinkler and alarm system",
    control_type: "technical",
    functional_range: "wide",
    primary_provider_id: provider_contractor.id,
    provider_distance: Decimal.new("2.5"),
    organization_id: org.id
  })
  |> Ash.create!()

control_fire_system =
  control_fire_system
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -10, :day),
    last_touched_by_user_id: user_sarah.id,
    current_quadrant: "service"
  })
  |> Ash.update!()

control_hvac =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "HVAC Ventilation System",
    description: "Building ventilation and air quality",
    control_type: "technical",
    functional_range: "wide",
    primary_provider_id: provider_contractor.id,
    provider_distance: Decimal.new("2.5"),
    organization_id: org.id
  })
  |> Ash.create!()

control_hvac =
  control_hvac
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -15, :day),
    last_touched_by_user_id: user_john.id,
    current_quadrant: "service"
  })
  |> Ash.update!()

# STRANGE QUADRANT: Distant touch + Remote provider
control_crane =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Overhead Crane Safety System",
    description: "Specialized crane with safety interlocks",
    control_type: "technical",
    functional_range: "narrow",
    primary_provider_id: provider_vendor.id,
    provider_distance: Decimal.new("4.5"),
    organization_id: org.id
  })
  |> Ash.create!()

control_crane =
  control_crane
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -200, :day),
    last_touched_by_user_id: user_mike.id,
    current_quadrant: "strange",
    failure_probability: Decimal.new("0.75")
  })
  |> Ash.update!()

control_emergency_shower =
  Control
  |> Ash.Changeset.for_create(:create, %{
    name: "Emergency Shower/Eyewash Station",
    description: "Vendor-maintained emergency equipment",
    control_type: "physical",
    functional_range: "narrow",
    primary_provider_id: provider_vendor.id,
    provider_distance: Decimal.new("4.5"),
    organization_id: org.id
  })
  |> Ash.create!()

control_emergency_shower =
  control_emergency_shower
  |> Ash.Changeset.for_update(:update, %{
    last_touched_at: DateTime.add(DateTime.utc_now(), -365, :day),
    last_touched_by_user_id: user_sarah.id,
    current_quadrant: "strange",
    failure_probability: Decimal.new("0.85")
  })
  |> Ash.update!()

IO.puts("✓ Created 9 controls:")
IO.puts("  • 2 in SELF quadrant (PPE, Toolbox)")
IO.puts("  • 2 in SPECIALIST quadrant (Confined Space, Forklift)")
IO.puts("  • 2 in SERVICE quadrant (Fire System, HVAC)")
IO.puts("  • 2 in STRANGE quadrant (Crane, Emergency Shower)")

# ========================================
# 4. CREATE HISTORICAL CLASSIFICATIONS
# ========================================
IO.puts("\n📈 Creating quadrant classification history...")

# Show PPE moving from self to service (if John stopped using it)
QuadrantClassification
|> Ash.Changeset.for_create(:create, %{
  control_id: control_ppe.id,
  quadrant: "self",
  time_since_touched_days: 5,
  provider_distance: Decimal.new("0.0"),
  reason: "initial_classification",
  organization_id: org.id
})
|> Ash.create!()

# Show Crane moving from service → specialist → strange over time
QuadrantClassification
|> Ash.Changeset.for_create(:create, %{
  control_id: control_crane.id,
  quadrant: "service",
  time_since_touched_days: 15,
  provider_distance: Decimal.new("4.5"),
  classified_at: DateTime.add(DateTime.utc_now(), -180, :day),
  reason: "initial_classification",
  organization_id: org.id
})
|> Ash.create!()

QuadrantClassification
|> Ash.Changeset.for_create(:create, %{
  control_id: control_crane.id,
  quadrant: "specialist",
  time_since_touched_days: 90,
  provider_distance: Decimal.new("4.5"),
  classified_at: DateTime.add(DateTime.utc_now(), -90, :day),
  reason: "time_decay",
  organization_id: org.id
})
|> Ash.create!()

QuadrantClassification
|> Ash.Changeset.for_create(:create, %{
  control_id: control_crane.id,
  quadrant: "strange",
  time_since_touched_days: 200,
  provider_distance: Decimal.new("4.5"),
  reason: "time_decay",
  organization_id: org.id
})
|> Ash.create!()

IO.puts("✓ Created classification history showing control movement")

# ========================================
# 5. CREATE ORGANIZATIONAL TRACES
# ========================================
IO.puts("\n📋 Creating organizational traces...")

# Incident with Emergency Shower
OrganizationalTrace
|> Ash.Changeset.for_create(:create, %{
  control_id: control_emergency_shower.id,
  trace_type: "incident_report",
  description: "Worker attempted to use emergency shower but it was not operational",
  severity: "high",
  recorded_by_user_id: user_sarah.id,
  organization_id: org.id
})
|> Ash.create!()

# Maintenance request for Crane
OrganizationalTrace
|> Ash.Changeset.for_create(:create, %{
  control_id: control_crane.id,
  trace_type: "maintenance_request",
  description: "Annual inspection overdue",
  severity: "medium",
  recorded_by_user_id: user_mike.id,
  organization_id: org.id
})
|> Ash.create!()

# Training record for Confined Space
OrganizationalTrace
|> Ash.Changeset.for_create(:create, %{
  control_id: control_confined_space.id,
  trace_type: "training_record",
  description: "Confined space entry training completed",
  recorded_by_user_id: user_mike.id,
  recorded_at: DateTime.add(DateTime.utc_now(), -45, :day),
  organization_id: org.id
})
|> Ash.create!()

# Inspection for Fire System
OrganizationalTrace
|> Ash.Changeset.for_create(:create, %{
  control_id: control_fire_system.id,
  trace_type: "inspection_log",
  description: "Monthly fire suppression system test - PASSED",
  recorded_by_user_id: user_sarah.id,
  recorded_at: DateTime.add(DateTime.utc_now(), -10, :day),
  organization_id: org.id
})
|> Ash.create!()

IO.puts("✓ Created 4 organizational traces (incidents, maintenance, training, inspections)")

# ========================================
# 6. CREATE COMPETENCY RECORDS
# ========================================
IO.puts("\n🎓 Creating competency records...")

# Mike's confined space competency (expiring soon)
CompetencyRecord
|> Ash.Changeset.for_create(:create, %{
  user_id: user_mike.id,
  control_id: control_confined_space.id,
  competency_level: "competent",
  last_training_date: Date.add(Date.utc_today(), -330),
  # Due in 35 days
  next_refresher_due: Date.add(Date.utc_today(), 35),
  training_hours: Decimal.new("8.0"),
  certified_by: "Safety Department",
  certification_expires: Date.add(Date.utc_today(), 35),
  organization_id: org.id
})
|> Ash.create!()

# John's forklift competency (already expired!)
CompetencyRecord
|> Ash.Changeset.for_create(:create, %{
  user_id: user_john.id,
  control_id: control_forklift.id,
  competency_level: "proficient",
  # 2 years ago
  last_training_date: Date.add(Date.utc_today(), -730),
  # Expired 1 year ago!
  next_refresher_due: Date.add(Date.utc_today(), -365),
  training_hours: Decimal.new("16.0"),
  certified_by: "Safety Department",
  certification_expires: Date.add(Date.utc_today(), -365),
  organization_id: org.id
})
|> Ash.create!()

# Sarah's general safety training
CompetencyRecord
|> Ash.Changeset.for_create(:create, %{
  user_id: user_sarah.id,
  control_id: control_fire_system.id,
  competency_level: "competent",
  last_training_date: Date.add(Date.utc_today(), -60),
  # Next year
  next_refresher_due: Date.add(Date.utc_today(), 305),
  training_hours: Decimal.new("4.0"),
  certified_by: "EquipCare Services",
  organization_id: org.id
})
|> Ash.create!()

IO.puts("✓ Created 3 competency records (1 expiring soon, 1 expired)")

# ========================================
# SUMMARY
# ========================================
IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("✅ Database seeded successfully!")
IO.puts(String.duplicate("=", 60))

IO.puts("\n📊 Summary:")
IO.puts("  • 1 Organization: Acme Construction Ltd")
IO.puts("  • 3 Users: John, Sarah, Mike")
IO.puts("  • 5 Providers: 2 users, 1 internal dept, 1 contractor, 1 vendor")
IO.puts("  • 9 Controls across all 4 quadrants:")

IO.puts("\n  🟢 SELF (Recent + Close):")
IO.puts("     - PPE (last touched 5 days ago)")
IO.puts("     - Toolbox Lock (last touched 2 days ago)")

IO.puts("\n  🔵 SPECIALIST (Distant + Close):")
IO.puts("     - Confined Space Entry (45 days ago, refresher needed)")
IO.puts("     - Forklift Cert (120 days ago, EXPIRED)")

IO.puts("\n  🟡 SERVICE (Recent + Remote):")
IO.puts("     - Fire System (10 days ago)")
IO.puts("     - HVAC System (15 days ago)")

IO.puts("\n  🔴 STRANGE (Distant + Remote):")
IO.puts("     - Overhead Crane (200 days ago, 75% failure risk)")
IO.puts("     - Emergency Shower (365 days ago, 85% failure risk)")

IO.puts("\n  📈 4 Quadrant classification history records")
IO.puts("  📋 4 Organizational traces")
IO.puts("  🎓 3 Competency records")

IO.puts("\n🚀 Ready to test! Try:")
IO.puts("  • Query controls requiring attention")
IO.puts("  • View quadrant classifications over time")
IO.puts("  • Check expiring competencies")
IO.puts("  • Review high-risk (strange quadrant) controls")
IO.puts("")
