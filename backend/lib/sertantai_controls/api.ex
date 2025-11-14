defmodule SertantaiControls.Api do
  @moduledoc """
  The main Ash Domain for Sertantai Controls.

  This domain defines the entry point for all Ash resources and actions.
  """

  use Ash.Domain

  resources do
    # Auth (read-only from sertantai-auth)
    resource(SertantaiControls.Auth.User)
    resource(SertantaiControls.Auth.Organization)

    # Safety domain
    resource(SertantaiControls.Safety.ControlProvider)
    resource(SertantaiControls.Safety.Control)
    resource(SertantaiControls.Safety.ProviderNetwork)
    resource(SertantaiControls.Safety.ControlInteraction)
    resource(SertantaiControls.Safety.QuadrantClassification)
    resource(SertantaiControls.Safety.OrganizationalTrace)
    resource(SertantaiControls.Safety.CompetencyRecord)
  end
end
