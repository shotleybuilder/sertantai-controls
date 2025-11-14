defmodule SertantaiControlsWeb.HealthController do
  use SertantaiControlsWeb, :controller

  @doc """
  Health check endpoint for monitoring and load balancers.
  Returns 200 OK with basic service status.
  """
  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "sertantai-controls",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end
end
