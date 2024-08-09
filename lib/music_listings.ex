defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  alias MusicListings.Crawler
  alias MusicListings.Events
  alias MusicListings.Venues
  alias MusicListingsSchema.IgnoredEvent
  alias MusicListingsSchema.Venue

  require Logger

  @spec data_last_updated_on :: String.t()
  defdelegate data_last_updated_on, to: Crawler

  @spec ignore_crawl_error(pos_integer()) :: IgnoredEvent
  defdelegate ignore_crawl_error(crawl_error_id), to: Crawler

  @spec list_events(list()) :: any()
  defdelegate list_events(opts \\ []), to: Events

  @spec get_venue!(pos_integer()) :: Venue
  defdelegate get_venue!(venue_id), to: Venues
end
