defmodule MusicListings.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Appsignal.CheckIn
  alias Appsignal.Logger.Handler, as: AppsignalLogHandler
  alias Appsignal.Phoenix.LiveView, as: AppsignalLiveView
  alias MusicListings.Analytics.TelemetryHandler
  alias MusicListings.Workers.DataRetrievalWorker

  @impl true
  def start(_type, _args) do
    appsignal_active? = Application.get_env(:appsignal, :config, [])[:active] == true

    if Application.get_env(:music_listings, :crawl_and_exit?) == true do
      children = [
        MusicListingsWeb.Telemetry,
        MusicListings.Repo,
        # Start the Finch HTTP client for sending emails
        {Finch, name: MusicListings.Finch},
        # Start the Finch HTTP client for Req with larger pool for crawling
        {Finch,
         name: MusicListings.ReqFinch,
         pools: %{
           :default => [size: 100, count: 4]
         }}
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: MusicListings.Supervisor]
      Supervisor.start_link(children, opts)

      if appsignal_active?, do: AppsignalLogHandler.add("crawler")

      # Wrap the crawl in an AppSignal cron check-in (start + finish) so a
      # missed or failed nightly run alerts. Falls back to a plain call when
      # AppSignal is inactive (dev/test, or before the push key is set).
      if appsignal_active? do
        CheckIn.cron("daily_crawl", fn -> DataRetrievalWorker.perform(%{}) end)
      else
        DataRetrievalWorker.perform(%{})
      end

      System.stop(0)
    else
      {:ok, _migrated} = EctoBootMigration.migrate(:music_listings)

      children = [
        MusicListingsWeb.Telemetry,
        MusicListings.Repo,
        {Oban, Application.fetch_env!(:music_listings, Oban)},
        {DNSCluster, query: Application.get_env(:music_listings, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: MusicListings.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: MusicListings.Finch},
        # Start the Finch HTTP client for Req with larger pool for crawling
        {Finch,
         name: MusicListings.ReqFinch,
         pools: %{
           :default => [size: 100, count: 4]
         }},
        # Start a worker by calling: MusicListings.Worker.start_link(arg)
        # {MusicListings.Worker, arg},
        # Start to serve requests, typically the last entry
        MusicListingsWeb.Endpoint
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: MusicListings.Supervisor]
      result = Supervisor.start_link(children, opts)

      # Persist first-party product-analytics telemetry events to the database.
      TelemetryHandler.attach()

      # HTTP requests, Ecto, Oban and Finch are auto-instrumented via the
      # configured otp_app; LiveView and log forwarding must be attached here.
      if appsignal_active? do
        AppsignalLiveView.attach()
        AppsignalLogHandler.add("phoenix")
      end

      result
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MusicListingsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
