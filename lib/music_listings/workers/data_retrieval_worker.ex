defmodule MusicListings.Workers.DataRetrievalWorker do
  @moduledoc """
  Worker which pulls venues from the DB and passes these off
  to the crawler to retrieve data
  """
  use Oban.Worker

  import Ecto.Query

  alias MusicListings.Crawler
  alias MusicListings.Repo
  alias MusicListingsSchema.Venue

  @impl Oban.Worker
  def perform(_job) do
    query = from(venue in Venue, where: venue.pull_events? == true)

    query
    |> Repo.all()
    |> Enum.map(&String.to_existing_atom("Elixir.#{&1.parser_module_name}"))
    |> Crawler.crawl(pull_data_from_www: true)

    :ok
  end
end