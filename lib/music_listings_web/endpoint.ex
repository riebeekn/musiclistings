defmodule MusicListingsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :music_listings

  # Health Check before SSL plug as HC is HTTP not HTTPS
  plug MusicListingsWeb.Plugs.HealthCheck

  if Mix.env() == :prod do
    plug Plug.SSL, rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto]
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_music_listings_key",
    signing_salt: "Q5Mw/3M9",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # gzip is enabled only in prod, where `mix phx.digest` generates fresh `.gz`
  # files at build time. In dev the watchers rewrite only the uncompressed
  # assets, so serving stale leftover `.gz` files would mask CSS/JS changes.
  plug Plug.Static,
    at: "/",
    from: :music_listings,
    gzip: Mix.env() == :prod,
    only: MusicListingsWeb.static_paths(),
    # Root-level files (favicon.ico, favicon.svg, apple-touch-icon.png) get
    # digested to hashed names in prod (e.g. favicon-<hash>.svg). Those hashed
    # names don't match the exact entries in :only, so without prefix matching
    # they 404. See Plug.Static :only_matching docs.
    only_matching: ~w(favicon apple-touch-icon)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :music_listings
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug MusicListingsWeb.Router
end
