defmodule MusicListings.Events do
  @moduledoc """
  Context module for event related functionality
  """
  import Ecto.Query

  alias Ecto.Changeset
  alias MusicListings.Accounts.User
  alias MusicListings.Events.EventInfo
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Events.RecentlyAddedRanker
  alias MusicListings.Events.ShowTimeInfo
  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsUtilities.DateHelpers

  @default_page 1
  @default_page_size 100

  @type list_events_opts ::
          {:page, pos_integer()}
          | {:page_size, pos_integer()}
          | {:venue_ids, list(pos_integer())}
          | {:order_by, list(atom())}
          | {:from_date, Date.t()}
          | {:sort_by, :title | :venue}
  @spec list_events(list(list_events_opts)) :: PagedEvents.t()
  def list_events(opts \\ []) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    venue_ids = Keyword.get(opts, :venue_ids, [])
    from_date = Keyword.get(opts, :from_date, nil)
    order_by_fields = Keyword.get(opts, :order_by, [:date, :title])
    sort_by = Keyword.get(opts, :sort_by, :title)

    today = DateHelpers.effective_today_eastern()
    start_date = from_date || today

    pagination_result =
      Event
      |> where([event], event.date >= ^start_date)
      |> where([event], is_nil(event.deleted_at))
      |> maybe_filter_by_venues(venue_ids)
      |> order_by(^order_by_fields)
      |> preload(:venue)
      |> Repo.paginate(page: page, page_size: page_size)

    grouped_events =
      pagination_result.entries
      |> Enum.group_by(&{&1.date, &1.title})
      |> Enum.map(fn {_key, events} -> build_event_info(events) end)
      |> Enum.group_by(& &1.date)
      |> Enum.map(fn {date, events} ->
        sorted_events = Enum.sort_by(events, &sort_key(&1, sort_by))
        {date, sorted_events}
      end)
      |> Enum.sort_by(fn {date, _events} -> date end, Date)

    %PagedEvents{
      events: grouped_events,
      current_page: pagination_result.page_number,
      total_pages: pagination_result.total_pages
    }
  end

  # "Recently added" feed: how far back (by inserted_at) to consider, and the upper
  # bound on candidate rows fetched before in-memory ranking (see RecentlyAddedRanker).
  @default_lookback_days 5
  @default_pool_size 500

  @type list_recently_added_events_opt ::
          {:lookback_days, pos_integer()}
          | {:pool_size, pos_integer()}
          | {:ticket_boost, number()}
          | {:diversity_decay, number()}
          | {:max_per_venue, pos_integer()}
          | {:limit, pos_integer()}
  @doc """
  Lists recently added, still-upcoming events ranked for the "Recently Added" feed.

  Fetches a bounded pool of events inserted within the last `:lookback_days` and delegates
  ordering to `RecentlyAddedRanker`, which boosts ticketed shows and caps per-venue
  representation so no single venue dominates. Returns a flat list of `EventInfo` structs
  in ranked order (one per show). See `RecentlyAddedRanker` for the tuning options, all of
  which are forwarded.
  """
  @spec list_recently_added_events([list_recently_added_events_opt]) :: [EventInfo.t()]
  def list_recently_added_events(opts \\ []) do
    lookback_days = Keyword.get(opts, :lookback_days, @default_lookback_days)
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)

    now = DateHelpers.now()
    today = DateHelpers.effective_today_eastern()
    inserted_since = DateTime.add(now, -lookback_days, :day)

    candidates =
      Event
      |> join(:inner, [event], venue in assoc(event, :venue))
      |> where([event], event.inserted_at >= ^inserted_since)
      |> where([event], event.date >= ^today)
      |> where([event], is_nil(event.deleted_at))
      |> where([_event, venue], venue.include_in_recently_added_feed?)
      |> order_by(desc: :inserted_at, desc: :id)
      |> limit(^pool_size)
      |> preload(:venue)
      |> Repo.all()

    candidates
    |> RecentlyAddedRanker.rank(now, opts)
    |> Enum.chunk_by(&{&1.venue_id, &1.date, &1.title})
    |> Enum.map(&build_event_info/1)
  end

  @spec list_upcoming_events() :: [Event.t()]
  def list_upcoming_events do
    today = DateHelpers.effective_today_eastern()

    Event
    |> where([event], event.date >= ^today)
    |> where([event], is_nil(event.deleted_at))
    |> order_by(asc: :date, asc: :title)
    |> preload(:venue)
    |> Repo.all()
  end

  @spec fetch_event(pos_integer()) :: {:ok, Event.t()} | {:error, :not_found}
  def fetch_event(event_id) do
    Event
    |> Repo.get(event_id)
    |> Repo.preload(:venue)
    |> case do
      nil -> {:error, :not_found}
      event -> {:ok, event}
    end
  end

  # Collapse one show's events (sharing a date/title) into a single EventInfo, gathering
  # their showtimes. Shared by the date-grouped listing and the recently added feed.
  defp build_event_info(events) do
    [first_show | _rest] = events

    shows =
      events
      |> Enum.map(fn event ->
        %ShowTimeInfo{
          event_id: event.id,
          time: event.time,
          ticket_url: event.ticket_url,
          details_url: event.details_url
        }
      end)
      |> Enum.sort_by(& &1.time)

    %EventInfo{
      date: first_show.date,
      title: first_show.title,
      openers: first_show.openers,
      venue: first_show.venue,
      price_lo: first_show.price_lo,
      price_hi: first_show.price_hi,
      price_format: first_show.price_format,
      age_restriction: first_show.age_restriction,
      showtimes: shows,
      has_multiple_showtimes?: Enum.count(shows) > 1,
      added_at: events |> Enum.map(& &1.inserted_at) |> Enum.min(DateTime)
    }
  end

  defp sort_key(event, :venue), do: event.venue.name
  defp sort_key(event, _title), do: event.title

  defp maybe_filter_by_venues(query, []), do: query

  defp maybe_filter_by_venues(query, venue_ids) when is_list(venue_ids) do
    query
    |> where([event], event.venue_id in ^venue_ids)
  end

  @spec list_submitted_events(User, list(list_events_opts)) :: PagedEvents.t()
  def list_submitted_events(user, opts \\ [])

  def list_submitted_events(%User{role: :admin}, opts) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)

    pagination_result =
      SubmittedEvent
      |> order_by(desc: :inserted_at, asc: :title)
      |> Repo.paginate(page: page, page_size: page_size)

    %PagedEvents{
      events: pagination_result.entries,
      current_page: pagination_result.page_number,
      total_pages: pagination_result.total_pages
    }
  end

  def list_submitted_events(_user, _opts) do
    {:error, :not_allowed}
  end

  @spec delete_event(User | nil, pos_integer()) :: {:ok, Event} | {:error, :not_allowed}
  def delete_event(%User{role: :admin}, event_id) do
    Event
    |> Repo.get!(event_id)
    |> Changeset.change(%{deleted_at: DateHelpers.now()})
    |> Repo.update()
  end

  def delete_event(_user, _event_id) do
    {:error, :not_allowed}
  end

  def fetch_submitted_event(submitted_event_id) do
    SubmittedEvent
    |> Repo.get(submitted_event_id)
    |> case do
      nil -> {:error, :submitted_event_not_found}
      submitted_event -> {:ok, submitted_event}
    end
  end
end
