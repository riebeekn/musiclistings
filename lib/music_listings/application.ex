defmodule MusicListings.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias MusicListings.Workers.DataRetrievalWorker

  @impl true
  def start(_type, _args) do
    if Application.get_env(:music_listings, :crawl_and_exit?) == true do
      children = [
        MusicListingsWeb.Telemetry,
        MusicListings.Repo,
        # Start the Finch HTTP client for sending emails
        {Finch, name: MusicListings.Finch}
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: MusicListings.Supervisor]
      Supervisor.start_link(children, opts)
      DataRetrievalWorker.perform(%{})

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
        # Start a worker by calling: MusicListings.Worker.start_link(arg)
        # {MusicListings.Worker, arg},
        # Start to serve requests, typically the last entry
        MusicListingsWeb.Endpoint
      ]

      # See https://hexdocs.pm/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: MusicListings.Supervisor]
      Supervisor.start_link(children, opts)
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
