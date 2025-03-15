defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  alias MusicListings.Crawler
  alias MusicListings.Events
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Price
  alias MusicListings.Repo
  alias MusicListings.Venues
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.Event
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
  defdelegate submit_event(attrs), to: Events

  @spec delete_event(User | nil, pos_integer()) :: {:ok, Event} | {:error, :not_allowed}
  defdelegate delete_event(user, event_id), to: Events

  @spec populate_event_from_submission(pos_integer()) ::
          {:ok, Event} | {:error, :submitted_event_not_found} | {:error, :venue_not_found}
  def populate_event_from_submission(submitted_event_id) do
    with {:ok, submitted_event} <- Events.fetch_submitted_event(submitted_event_id),
         {:ok, venue} <- Venues.fetch_venue_by_name(submitted_event.venue) do
      external_id =
        "#{submitted_event.id}_#{ParseHelpers.build_id_from_title_and_date(submitted_event.title, submitted_event.date)}"

      price = Price.new(submitted_event.price)

      %Event{
        external_id: external_id,
        venue_id: venue.id,
        title: submitted_event.title,
        headliner: submitted_event.title,
        openers: [],
        date: submitted_event.date,
        time: ParseHelpers.build_time_from_time_string(submitted_event.time),
        price_format: price.format,
        price_lo: price.lo,
        price_hi: price.hi,
        age_restriction: :unknown,
        details_url: submitted_event.url
      }
      |> Repo.insert()
    end
  end

  @type list_venue_opts :: {:restrict_to_pulled_venues?, boolean()}
  @spec list_venues(list(list_venue_opts)) :: list(VenueSummary)
  defdelegate list_venues(opts \\ []), to: Venues

  @spec get_venue!(pos_integer()) :: Venue
  defdelegate get_venue!(venue_id), to: Venues
end
