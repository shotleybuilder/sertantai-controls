defmodule SertantaiControlsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :sertantai_controls

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_sertantai_controls_key",
    signing_salt: "m2DMKQLC",
    same_site: "Lax"
  ]

  # socket "/live", Phoenix.LiveView.Socket,
  #   websocket: [connect_info: [session: @session_options]],
  #   longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :sertantai_controls,
    gzip: false,
    only: SertantaiControlsWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :sertantai_controls
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # CORS configuration
  plug Corsica,
    origins: [
      # Vite dev server
      ~r{^https?://localhost:5173$},
      ~r{^https?://127\.0\.0\.1:5173$},
      System.get_env("FRONTEND_URL") || ""
    ],
    allow_credentials: true,
    allow_headers: ["content-type", "authorization"],
    max_age: 600

  plug SertantaiControlsWeb.Router
end
