defmodule SertantaiControlsWeb.Router do
  use SertantaiControlsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug SertantaiControlsWeb.Plugs.VerifyAuthToken
  end

  # Health check endpoints (no /api prefix, no authentication required)
  scope "/", SertantaiControlsWeb do
    pipe_through :api
    get "/health", HealthController, :index
    get "/health/detailed", HealthController, :show
  end

  # Public API endpoints (no authentication)
  scope "/api/public", SertantaiControlsWeb do
    pipe_through :api
    get "/hello", HelloController, :index
  end

  # Protected API endpoints (requires authentication)
  scope "/api", SertantaiControlsWeb do
    pipe_through [:api, :authenticated]

    # ElectricSQL sync endpoint
    # Proxies shape requests to Electric service with automatic tenant filtering
    get "/electric/sync", ElectricController, :sync

    # Protected routes will go here
    # Example: resources "/controls", ControlController
  end
end
