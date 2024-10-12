defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  alias MusicListings.Crawler
  alias MusicListings.Events
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Venues
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.IgnoredEvent
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsSchema.Venue

  require Logger

  @spec data_last_updated_on :: String.t()
  defdelegate data_last_updated_on, to: Crawler

  @spec ignore_crawl_error(pos_integer()) :: IgnoredEvent
  defdelegate ignore_crawl_error(crawl_error_id), to: Crawler

  @type list_events_opts ::
          {:page, pos_integer()}
          | {:page_size, pos_integer()}
          | {:venue_ids, list(pos_integer())}
  @spec list_events(list(list_events_opts)) :: PagedEvents.t()
  defdelegate list_events(opts \\ []), to: Events

  @spec submit_event(
          attrs :: %{
            title: String.t(),
            venue: String.t(),
            date: Date.t(),
            time: String.t(),
            price: String.t(),
            url: String.t()
          }
        ) :: {:ok, SubmittedEvent.t()} | {:error, Ecto.Changeset.t()}
  defdelegate submit_event(attrs), to: Events

  @spec list_venues :: list(VenueSummary)
  defdelegate list_venues, to: Venues

  @spec get_venue!(pos_integer()) :: Venue
  defdelegate get_venue!(venue_id), to: Venues
end
