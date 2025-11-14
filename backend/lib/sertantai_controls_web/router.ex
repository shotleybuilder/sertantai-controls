defmodule SertantaiControlsWeb.Router do
  use SertantaiControlsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check endpoint (no /api prefix)
  scope "/", SertantaiControlsWeb do
    pipe_through :api
    get "/health", HealthController, :index
  end

  # API endpoints
  scope "/api", SertantaiControlsWeb do
    pipe_through :api
    get "/hello", HelloController, :index
  end
end
