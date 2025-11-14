defmodule SertantaiControls.Safety.ControlInteraction do
  @moduledoc """
  Records each time a user interacts with a control (use, inspect, maintain, test).
  Automatically updates the control's last_touched timestamp.
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: SertantaiControls.Api

  postgres do
    table("control_interactions")
    repo(SertantaiControls.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :control_id, :uuid do
      allow_nil?(false)
    end

    attribute :user_id, :uuid do
      allow_nil?(false)
    end

    attribute :interaction_type, :string do
      allow_nil?(false)
    end

    attribute(:duration_minutes, :integer)

    attribute(:notes, :string)

    attribute :issues_found, :boolean do
      default(false)
    end

    # Capture pre and post quadrant for tracking movement
    attribute(:quadrant_before, :string)

    attribute(:quadrant_after, :string)

    attribute :organization_id, :uuid do
      allow_nil?(false)
    end

    create_timestamp(:inserted_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to :control, SertantaiControls.Safety.Control
    belongs_to :user, SertantaiControls.Auth.User
  end

  actions do
    defaults([:read, :destroy])

    create :create do
      accept([
        :control_id,
        :user_id,
        :interaction_type,
        :duration_minutes,
        :notes,
        :issues_found,
        :organization_id
      ])

      # Automatically update the control's last_touched
      change(
        after_action(fn _changeset, record ->
          control = Ash.get!(SertantaiControls.Safety.Control, record.control_id)

          # Store quadrant before touch
          quadrant_before = control.current_quadrant

          # Touch the control (triggers quadrant recalculation)
          updated_control =
            control
            |> Ash.Changeset.for_update(:touch, %{}, arguments: %{user_id: record.user_id})
            |> Ash.update!()

          # Update interaction record with before/after quadrants
          record
          |> Ash.Changeset.for_update(:update_quadrants, %{
            quadrant_before: quadrant_before,
            quadrant_after: updated_control.current_quadrant
          })
          |> Ash.update!()

          {:ok, record}
        end)
      )
    end

    update :update_quadrants do
      require_atomic?(false)
      accept([:quadrant_before, :quadrant_after])
    end
  end

  code_interface do
    define(:create)
    define(:read)
  end

  validations do
    validate(fn changeset, _context ->
      case Ash.Changeset.get_attribute(changeset, :interaction_type) do
        type when type in ["use", "inspect", "maintain", "test"] ->
          :ok

        nil ->
          :ok

        _ ->
          {:error,
           field: :interaction_type, message: "must be one of: use, inspect, maintain, test"}
      end
    end)
  end
end
