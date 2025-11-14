defmodule SertantaiControls.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SertantaiControlsWeb.Telemetry,
      SertantaiControls.Repo,
      {DNSCluster,
       query: Application.get_env(:sertantai_controls, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SertantaiControls.PubSub},
      # Start a worker by calling: SertantaiControls.Worker.start_link(arg)
      # {SertantaiControls.Worker, arg},
      # Start to serve requests, typically the last entry
      SertantaiControlsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SertantaiControls.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SertantaiControlsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
