defmodule SertantaiControls.Repo.Migrations.EnableRlsForTenantIsolation do
  @moduledoc """
  Enable Row-Level Security (RLS) for multi-tenant data isolation.

  This migration:
  1. Enables RLS on all tenant-scoped tables
  2. Creates policies that filter rows by organization_id
  3. Sets up session variable for org_id from JWT claims

  RLS provides database-level security ensuring:
  - Users can only access data from their organization
  - Even if application code has bugs, data remains isolated
  - Works with ElectricSQL sync to enforce tenant boundaries
  """

  use Ecto.Migration

  def up do
    # List of tenant-scoped tables that need RLS
    tenant_tables = [
      "controls",
      "control_interactions",
      "control_providers",
      "competency_records",
      "organizational_traces",
      "provider_networks",
      "quadrant_classifications"
    ]

    # Enable RLS on each table
    for table <- tenant_tables do
      execute("ALTER TABLE #{table} ENABLE ROW LEVEL SECURITY")
    end

    # Create RLS policies for each table
    # Policy: SELECT - Users can read rows from their organization
    for table <- tenant_tables do
      execute("""
      CREATE POLICY tenant_isolation_select ON #{table}
        FOR SELECT
        USING (
          organization_id = COALESCE(
            current_setting('app.current_org_id', true)::uuid,
            '00000000-0000-0000-0000-000000000000'::uuid
          )
        )
      """)
    end

    # Policy: INSERT - Users can insert rows with their organization_id
    for table <- tenant_tables do
      execute("""
      CREATE POLICY tenant_isolation_insert ON #{table}
        FOR INSERT
        WITH CHECK (
          organization_id = COALESCE(
            current_setting('app.current_org_id', true)::uuid,
            '00000000-0000-0000-0000-000000000000'::uuid
          )
        )
      """)
    end

    # Policy: UPDATE - Users can update rows from their organization
    for table <- tenant_tables do
      execute("""
      CREATE POLICY tenant_isolation_update ON #{table}
        FOR UPDATE
        USING (
          organization_id = COALESCE(
            current_setting('app.current_org_id', true)::uuid,
            '00000000-0000-0000-0000-000000000000'::uuid
          )
        )
        WITH CHECK (
          organization_id = COALESCE(
            current_setting('app.current_org_id', true)::uuid,
            '00000000-0000-0000-0000-000000000000'::uuid
          )
        )
      """)
    end

    # Policy: DELETE - Users can delete rows from their organization
    for table <- tenant_tables do
      execute("""
      CREATE POLICY tenant_isolation_delete ON #{table}
        FOR DELETE
        USING (
          organization_id = COALESCE(
            current_setting('app.current_org_id', true)::uuid,
            '00000000-0000-0000-0000-000000000000'::uuid
          )
        )
      """)
    end

    # Create function to set org_id from JWT claims
    # This will be called by the application when handling authenticated requests
    execute("""
    CREATE OR REPLACE FUNCTION set_current_org_id(org_id uuid)
    RETURNS void AS $$
    BEGIN
      PERFORM set_config('app.current_org_id', org_id::text, false);
    END;
    $$ LANGUAGE plpgsql;
    """)
  end

  def down do
    # Drop function
    execute("DROP FUNCTION IF EXISTS set_current_org_id(uuid)")

    # List of tenant-scoped tables
    tenant_tables = [
      "controls",
      "control_interactions",
      "control_providers",
      "competency_records",
      "organizational_traces",
      "provider_networks",
      "quadrant_classifications"
    ]

    # Drop policies
    for table <- tenant_tables do
      execute("DROP POLICY IF EXISTS tenant_isolation_select ON #{table}")
      execute("DROP POLICY IF EXISTS tenant_isolation_insert ON #{table}")
      execute("DROP POLICY IF EXISTS tenant_isolation_update ON #{table}")
      execute("DROP POLICY IF EXISTS tenant_isolation_delete ON #{table}")
    end

    # Disable RLS
    for table <- tenant_tables do
      execute("ALTER TABLE #{table} DISABLE ROW LEVEL SECURITY")
    end
  end
end
