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
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  music_listings: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

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
       # run at 7am UTC which is 3am EST
       {"0 7 * * *", MusicListings.Workers.DataRetrievalWorker, max_attempts: 1}
     ]}
  ]

# TZ config
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Set env
config :music_listings, env: Mix.env()

# Error tracker config
config :error_tracker,
  repo: MusicListings.Repo,
  otp_app: :music_listings

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
