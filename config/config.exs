# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :music_listings,
  ecto_repos: [MusicListings.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :music_listings, MusicListingsWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MusicListingsWeb.ErrorHTML, json: MusicListingsWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MusicListings.PubSub,
  live_view: [signing_salt: "C9RSRko8"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :music_listings, MusicListings.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  music_listings: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  music_listings: [
    args: ~w(
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure HB logger
config :honeybadger,
  use_logger: true,
  insights_enabled: true

# AppSignal (APM) base config — activated for prod in runtime.exs.
# otp_app enables automatic Ecto / Oban / Finch (HTTP) instrumentation.
config :appsignal, :config,
  otp_app: :music_listings,
  name: "Toronto Music Listings",
  env: Mix.env(),
  active: false,
  # Safety net: application.ex intentionally skips Appsignal.Phoenix.LiveView.attach/0,
  # so nothing should emit into this namespace. If someone re-adds attach/0, this keeps
  # the per-callback spans (~7-10 per pageview) from silently eating the request quota.
  ignore_namespaces: ["live_view"],
  # Machine traffic we don't performance-tune. The "/" -> "/events" redirect goes through
  # a plain plug rather than a Phoenix controller, so AppSignal names it by route pattern
  # instead of Controller#action.
  ignore_actions: [
    "MusicListingsWeb.SitemapController#index",
    "MusicListingsWeb.FeedController#index",
    "GET /"
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Oban config
config :music_listings, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10],
  repo: MusicListings.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # run at 6am UTC which is 3am EST
       # ... switched to no longer run via Oban but via Render Cron Job
       # {"0 6 * * *", MusicListings.Workers.DataRetrievalWorker, max_attempts: 1}
       # run at 7am UTC
       # ... switched the purger off for now
       # {"0 7 * * *", MusicListings.Workers.PurgeEventsWorker, max_attempts: 1},
       # run daily at 13:00 UTC (~9am Eastern) - weekly parser pullback check
       {"0 13 * * *", MusicListings.Workers.ParserHealthWorker, max_attempts: 1},
       # run Mondays at 13:00 UTC (~9am Eastern) - weekly rail traction digest
       {"0 13 * * 1", MusicListings.Workers.NewThisWeekAnalyticsWorker, max_attempts: 1}
     ]}
  ]

# FunWithFlags - feature flags persisted via Ecto (no Redis).
config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: MusicListings.Repo,
  ecto_table_name: "feature_flags"

# Cache disabled: flags are used sparingly (toggling UI features on/off), so the
# extra indexed DB lookup per check is negligible and not worth a caching layer.
# This also means toggles take effect immediately with no staleness, and removes
# the need for cross-node cache-bust notifications.
# NOTE: with the cache off, a flag check hits the DB every time, so check a flag
# once per request and reuse the boolean - don't call enabled?/1 inside a loop.
config :fun_with_flags, :cache, enabled: false
config :fun_with_flags, :cache_bust_notifications, enabled: false

# TZ config
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Set env
config :music_listings, env: Mix.env()

config :music_listings, :http_client, MusicListings.HttpClient.Req

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
