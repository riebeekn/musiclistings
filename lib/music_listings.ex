defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  alias MusicListings.Crawler
  alias MusicListings.Events
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Venues
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.IgnoredEvent
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsSchema.Venue
  alias MusicListingsServices.EventSubmissionService

  require Logger

  @spec data_last_updated_on :: String.t()
  defdelegate data_last_updated_on, to: Crawler

  @spec ignore_crawl_error(pos_integer()) :: IgnoredEvent
  defdelegate ignore_crawl_error(crawl_error_id), to: Crawler

  @type list_events_opts ::
          {:page, pos_integer()}
          | {:page_size, pos_integer()}
          | {:venue_ids,
             list(pos_integer())
             | {:order_by, list(atom())}}
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
  defdelegate submit_event(attrs), to: EventSubmissionService, as: :process_submitted_event

  @spec delete_event(User | nil, pos_integer()) :: {:ok, Event} | {:error, :not_allowed}
  defdelegate delete_event(user, event_id), to: Events

  @spec approve_submitted_event(pos_integer()) :: {:ok, Event} | {:error, atom()}
  defdelegate approve_submitted_event(submitted_event_id), to: EventSubmissionService

  @type list_venue_opts :: {:restrict_to_pulled_venues?, boolean()}
  @spec list_venues(list(list_venue_opts)) :: list(VenueSummary)
  defdelegate list_venues(opts \\ []), to: Venues

  @spec get_venue!(pos_integer()) :: Venue
  defdelegate get_venue!(venue_id), to: Venues
end
