defmodule MusicListings.Events do
  @moduledoc """
  Context module for event related functionality
  """
  import Ecto.Query

  alias Ecto.Changeset
  alias MusicListings.Accounts.User
  alias MusicListings.Events.EventInfo
  alias MusicListings.Events.EventSuggestion
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Events.RecentlyAddedRanker
  alias MusicListings.Events.ShowTimeInfo
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsUtilities.DateHelpers

  @default_page 1
  @default_page_size 100

  # Typeahead: how many suggestions to offer, and how many dates any single show may
  # claim of them.  A tour playing two nights should surface both - someone who finds
  # night one sold out needs to know night two exists - but a weekly residency running
  # sixty dates would otherwise fill the dropdown by itself.
  @default_suggestion_limit 8
  @max_suggestion_dates_per_show 3

  @type list_events_opts ::
          {:page, pos_integer()}
          | {:page_size, pos_integer()}
          | {:venue_ids, list(pos_integer())}
          | {:from_date, Date.t()}
          | {:sort_by, :title | :venue}
          | {:search, String.t() | nil}
  @spec list_events(list(list_events_opts)) :: PagedEvents.t()
  def list_events(opts \\ []) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    venue_ids = Keyword.get(opts, :venue_ids, [])
    from_date = Keyword.get(opts, :from_date, nil)
    sort_by = Keyword.get(opts, :sort_by, :title)
    search = Keyword.get(opts, :search, nil)

    today = DateHelpers.effective_today_eastern()
    start_date = from_date || today
    night_cutoff = DateHelpers.night_cutoff_time()

    # Late-night shows (before the cutoff) belong to the previous night out, so
    # we filter/order/group by that "night date".  Stored date/time stay true -
    # see MusicListingsUtilities.DateHelpers.night_date/2.
    pagination_result =
      Event
      |> where_upcoming(start_date, night_cutoff)
      |> maybe_filter_by_venues(venue_ids)
      |> maybe_filter_by_search(search)
      |> order_by(
        [event],
        asc:
          fragment(
            "(? - (CASE WHEN ? IS NOT NULL AND ? < ? THEN 1 ELSE 0 END))",
            event.date,
            event.time,
            event.time,
            ^night_cutoff
          ),
        asc: event.title
      )
      |> preload(:venue)
      |> Repo.paginate(page: page, page_size: page_size)

    grouped_events =
      pagination_result.entries
      |> Enum.group_by(&{night_date(&1), &1.title})
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

  @doc """
  Counts upcoming events currently carrying a TicketNetwork (resale) link.

  This is the exposure behind the resale click numbers in the weekly analytics
  email: without it a fall in clicks can't be told apart from a fall in how many
  events have a resale link at all, which matters while the catalog's
  no-inventory rows are being filtered out.
  """
  @spec count_events_with_resale_link() :: non_neg_integer()
  def count_events_with_resale_link do
    today = DateHelpers.effective_today_eastern()

    Event
    |> where([event], event.date >= ^today)
    |> where([event], is_nil(event.deleted_at))
    |> where([event], not is_nil(event.ticketnetwork_url))
    |> Repo.aggregate(:count)
  end

  @doc """
  Lists the events created by a given crawl, sorted by venue.

  The crawl summary row is inserted when the crawl starts, so any event inserted
  at or after that point was created by that crawl - events carry no reference to
  the crawl that created them.
  """
  @spec list_events_added_during_crawl(CrawlSummary.t()) :: [Event.t()]
  def list_events_added_during_crawl(%CrawlSummary{inserted_at: crawl_started_at}) do
    Event
    |> where([event], event.inserted_at >= ^crawl_started_at)
    |> where([event], is_nil(event.deleted_at))
    |> join(:inner, [event], venue in assoc(event, :venue))
    |> order_by([event, venue], asc: venue.name, asc: event.date, asc: event.title)
    |> preload([event, venue], venue: venue)
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
          ticketnetwork_url: event.ticketnetwork_url,
          details_url: event.details_url
        }
      end)
      |> Enum.sort_by(&DateHelpers.night_ordered_time_key(&1.time))

    %EventInfo{
      date: night_date(first_show),
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

  @doc """
  Returns up to `:limit` typeahead suggestions for `search_term`, newest-first by night date.

  Each date gets its own suggestion, so a two-night run offers both - the alternative hides
  the second night from anyone who finds the first sold out.  A single show (one title at one
  venue) is capped at `@max_suggestion_dates_per_show` of its earliest dates so a long-running
  residency can't crowd everything else out; the scoped listing below the dropdown always has
  the complete set.

  Matching covers the full bill (title, headliner and openers), so each suggestion carries its
  openers - otherwise a row matched on a support act looks like it matched nothing at all.
  Returns `[]` for a blank term or one with no usable tokens.
  """
  @spec search_event_titles(String.t() | nil, keyword()) :: [EventSuggestion.t()]
  def search_event_titles(search_term, opts \\ [])

  def search_event_titles(nil, _opts), do: []

  def search_event_titles(search_term, opts) when is_binary(search_term) do
    limit = Keyword.get(opts, :limit, @default_suggestion_limit)

    if search_tokens(search_term) == [] do
      []
    else
      start_date = DateHelpers.effective_today_eastern()
      night_cutoff = DateHelpers.night_cutoff_time()

      # The cap is applied in SQL rather than by trimming the result in Elixir: ranking has
      # to see every matching date to know which are a show's earliest, and a residency with
      # sixty dates would otherwise swallow any pool of rows small enough to be worth fetching.
      ranked_events =
        Event
        |> where_upcoming(start_date, night_cutoff)
        |> maybe_filter_by_search(search_term)
        |> select([event], %{
          id: event.id,
          date_rank:
            over(row_number(),
              partition_by: [event.title, event.venue_id],
              order_by: [
                asc:
                  fragment(
                    "(? - (CASE WHEN ? IS NOT NULL AND ? < ? THEN 1 ELSE 0 END))",
                    event.date,
                    event.time,
                    event.time,
                    ^night_cutoff
                  ),
                asc: event.id
              ]
            )
        })

      Event
      |> join(:inner, [event], ranked in subquery(ranked_events), on: ranked.id == event.id)
      |> where([_event, ranked], ranked.date_rank <= ^@max_suggestion_dates_per_show)
      |> order_by(
        [event],
        asc:
          fragment(
            "(? - (CASE WHEN ? IS NOT NULL AND ? < ? THEN 1 ELSE 0 END))",
            event.date,
            event.time,
            event.time,
            ^night_cutoff
          ),
        asc: event.title
      )
      |> limit(^limit)
      |> preload(:venue)
      |> Repo.all()
      |> Enum.map(
        &%EventSuggestion{
          event_id: &1.id,
          title: &1.title,
          date: night_date(&1),
          venue_name: &1.venue.name,
          openers: &1.openers || []
        }
      )
    end
  end

  defp night_date(event), do: DateHelpers.night_date(event.date, event.time)

  defp sort_key(event, :venue), do: event.venue.name
  defp sort_key(event, _title), do: event.title

  defp maybe_filter_by_venues(query, []), do: query

  defp maybe_filter_by_venues(query, venue_ids) when is_list(venue_ids) do
    query
    |> where([event], event.venue_id in ^venue_ids)
  end

  # Restricts to live (non-deleted) events on or after `start_date`.  Late-night shows
  # (before the cutoff) belong to the previous night out, so the comparison is against
  # that computed "night date" rather than the stored one - the stored date/time stay
  # true.  See MusicListingsUtilities.DateHelpers.night_date/2.
  defp where_upcoming(query, start_date, night_cutoff) do
    query
    |> where(
      [event],
      fragment(
        "(? - (CASE WHEN ? IS NOT NULL AND ? < ? THEN 1 ELSE 0 END)) >= ?",
        event.date,
        event.time,
        event.time,
        ^night_cutoff,
        ^start_date
      )
    )
    |> where([event], is_nil(event.deleted_at))
  end

  defp maybe_filter_by_search(query, nil), do: query

  defp maybe_filter_by_search(query, search_term) when is_binary(search_term) do
    search_term
    |> search_tokens()
    |> Enum.reduce(query, fn token, acc ->
      pattern = "%#{escape_like(token)}%"

      # Each token has to appear somewhere on the bill, but not all in the same field:
      # "mintzer trio" should still find a Bob Mintzer show whose opener is a trio.
      # openers is a text[], so it is flattened to a single string first - a token can
      # never contain a space (search_tokens/1 splits on whitespace), so joining can't
      # produce a false match across two adjacent openers.
      where(
        acc,
        [event],
        ilike(event.title, ^pattern) or ilike(event.headliner, ^pattern) or
          fragment("array_to_string(coalesce(?, '{}'), ' ') ILIKE ?", event.openers, ^pattern)
      )
    end)
  end

  # Splits a raw search string into the tokens we actually match on.  Every token has to
  # match (AND), so "bob quartet" finds "Bob Mintzer Quartet".  Single characters are
  # dropped - they match nearly everything and just slow the query down.
  defp search_tokens(search_term) do
    search_term
    |> String.trim()
    |> String.split(~r/\s+/, trim: true)
    |> Enum.reject(&(String.length(&1) < 2))
  end

  # LIKE treats %, _ and \ as syntax, so a user typing "%" would otherwise match every
  # row.  Escape them before interpolating into the pattern.
  defp escape_like(token) do
    token
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end

  @spec list_submitted_events(User, list(list_events_opts)) :: PagedEvents.t()
  def list_submitted_events(user, opts \\ [])

  def list_submitted_events(%User{role: :admin}, opts) do
    page = Keyword.get(opts, :page, @default_page)
    page_size = Keyword.get(opts, :page_size, @default_page_size)

    pagination_result =
      SubmittedEvent
      |> where([submitted_event], is_nil(submitted_event.deleted_at))
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

  @spec delete_submitted_events(User, list()) ::
          {:ok, non_neg_integer()} | {:error, :not_allowed}
  def delete_submitted_events(%User{role: :admin}, submitted_event_ids) do
    {count, _result} =
      SubmittedEvent
      |> where([submitted_event], submitted_event.id in ^submitted_event_ids)
      |> Repo.update_all(set: [deleted_at: DateHelpers.now()])

    {:ok, count}
  end

  def delete_submitted_events(_user, _submitted_event_ids) do
    {:error, :not_allowed}
  end

  @doc """
  Updates an existing submitted event (admin only). Lets an admin fix details such as a
  misspelled venue name or an invalid time/price before approving the submission.
  """
  @spec update_submitted_event(User, pos_integer(), map()) ::
          {:ok, SubmittedEvent.t()}
          | {:error, Ecto.Changeset.t() | :not_allowed | :submitted_event_not_found}
  def update_submitted_event(%User{role: :admin} = user, submitted_event_id, attrs) do
    with {:ok, submitted_event} <- fetch_submitted_event(user, submitted_event_id) do
      submitted_event
      |> SubmittedEvent.changeset(attrs)
      |> Repo.update()
    end
  end

  def update_submitted_event(_user, _submitted_event_id, _attrs) do
    {:error, :not_allowed}
  end

  def fetch_submitted_event(%User{role: :admin}, submitted_event_id) do
    SubmittedEvent
    |> Repo.get(submitted_event_id)
    |> case do
      nil -> {:error, :submitted_event_not_found}
      submitted_event -> {:ok, submitted_event}
    end
  end

  def fetch_submitted_event(_user, _submitted_event_id) do
    {:error, :not_allowed}
  end
end
