defmodule MusicListings.Affiliates.TicketNetwork do
  @moduledoc """
  Populates `events.ticketnetwork_url` from the TicketNetwork catalog.

  Runs after the nightly crawl (see
  `MusicListings.Workers.DataRetrievalWorker`), once our own event data is up to
  date.  The affiliate URL is written only from here - the crawler deliberately
  leaves the column alone, since re-parsing a venue page tells us nothing about
  TicketNetwork's inventory.

  The pass is self-healing: every upcoming event at a venue TicketNetwork covers
  is reconsidered on each run, and any event that no longer matches has its link
  cleared.  A product that has been delisted must not leave a dead link behind.

  `locked_from_updates?` is deliberately ignored here.  That flag protects an
  event's crawled details from being overwritten by a re-parse; it says nothing
  about TicketNetwork's inventory.
  """
  import Ecto.Query

  alias MusicListings.Affiliates.TicketNetwork.Client
  alias MusicListings.Affiliates.TicketNetwork.Matcher
  alias MusicListings.Affiliates.TicketNetwork.VenueMap
  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue

  require Logger

  defmodule Stats do
    @moduledoc """
    Outcome of a TicketNetwork matching run, summarised for the crawl email.
    """
    @type t :: %__MODULE__{
            matched: non_neg_integer(),
            linked: non_neg_integer(),
            cleared: non_neg_integer(),
            unmatched_items: non_neg_integer(),
            untracked_items: non_neg_integer(),
            consecutive_runs: [Matcher.consecutive_run()],
            venue_names: %{pos_integer() => String.t()}
          }

    defstruct matched: 0,
              linked: 0,
              cleared: 0,
              unmatched_items: 0,
              untracked_items: 0,
              consecutive_runs: [],
              venue_names: %{}
  end

  @doc """
  Fetches the catalog, matches it against our upcoming events and writes the
  results.

  Returns `{:ok, :skipped}` when no API credentials are configured, which is the
  normal state in dev and test.
  """
  @spec run(keyword()) :: {:ok, Stats.t()} | {:ok, :skipped} | {:error, term()}
  def run(opts \\ []) do
    with {:ok, analysis} <- analyze(opts) do
      {:ok, persist(analysis, Keyword.get(opts, :dry_run, false))}
    end
  end

  @doc """
  Runs the pass and returns its outcome, logging rather than raising on failure.
  Used by the nightly crawl, where a TicketNetwork outage must not fail the
  crawl or suppress the summary email.

  Returns the stats on success, `:skipped` when no credentials are configured,
  and `{:error, reason}` otherwise - the caller reports the failure in the crawl
  summary email, so a timed-out catalog doesn't look like a night with nothing
  to say.
  """
  @spec run_quietly(keyword()) :: Stats.t() | :skipped | {:error, term()}
  def run_quietly(opts \\ []) do
    case run(opts) do
      {:ok, stats} ->
        stats

      {:error, reason} = error ->
        Logger.error("TicketNetwork matching failed: #{inspect(reason)}")
        error
    end
  rescue
    error ->
      Logger.error("TicketNetwork matching crashed: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Fetches and matches the catalog without writing anything, returning the full
  match result alongside the stats.

  This is what `mix match_ticket_network --dry-run` reports on, and is how the
  venue map and similarity threshold get checked against real data.
  """
  @spec analyze(keyword()) ::
          {:ok, %{result: Matcher.result(), events: [Event.t()], venue_names: map()}}
          | {:ok, :skipped}
          | {:error, term()}
  def analyze(opts \\ []) do
    today = Keyword.get(opts, :today, Date.utc_today())

    if Client.configured?() do
      with {:ok, items} <- Client.fetch_items(today) do
        venue_ids = venue_ids_by_parser_module_name()
        events = upcoming_events(Map.values(venue_ids), today)

        {:ok,
         %{
           result: Matcher.match(items, events, venue_ids),
           events: events,
           venue_names: venue_names()
         }}
      end
    else
      {:ok, :skipped}
    end
  end

  @doc """
  Writes the results of an analysis the caller already holds, so a caller that
  has run `analyze/1` doesn't have to fetch the catalog a second time.
  """
  @spec apply_analysis(map() | :skipped) :: Stats.t() | :skipped
  def apply_analysis(analysis), do: persist(analysis, false)

  @doc """
  Summarises an analysis without writing anything.
  """
  @spec stats(map() | :skipped) :: Stats.t() | :skipped
  def stats(analysis), do: persist(analysis, true)

  defp persist(:skipped, _dry_run?), do: :skipped

  defp persist(%{result: result, events: events, venue_names: venue_names}, dry_run?) do
    urls_by_event_id = Map.new(result.matches, &{&1.event_id, &1.url})

    {linked, cleared} =
      events
      |> Enum.reject(fn event ->
        Map.get(urls_by_event_id, event.id) == event.ticketnetwork_url
      end)
      |> Enum.reduce({0, 0}, fn event, counts ->
        write(event, Map.get(urls_by_event_id, event.id), counts, dry_run?)
      end)

    %Stats{
      matched: length(result.matches),
      linked: linked,
      cleared: cleared,
      unmatched_items: length(result.unmatched_items),
      untracked_items: result.untracked_labels |> Map.values() |> Enum.sum(),
      consecutive_runs: result.consecutive_runs,
      venue_names: venue_names
    }
  end

  defp write(_event, url, {linked, cleared}, true) do
    if is_nil(url), do: {linked, cleared + 1}, else: {linked + 1, cleared}
  end

  defp write(event, url, {linked, cleared}, false) do
    event
    |> Ecto.Changeset.change(%{ticketnetwork_url: url})
    |> Repo.update()
    |> case do
      {:ok, _event} when is_nil(url) ->
        {linked, cleared + 1}

      {:ok, _event} ->
        {linked + 1, cleared}

      {:error, changeset} ->
        Logger.error("TicketNetwork: failed to update event #{event.id}: #{inspect(changeset)}")
        {linked, cleared}
    end
  end

  # TicketNetwork's venue labels resolve to parser module names, which are
  # stable across environments; venue ids are not.
  defp venue_ids_by_parser_module_name do
    parser_module_names = VenueMap.parser_module_names()

    query =
      from venue in Venue,
        where: venue.parser_module_name in ^parser_module_names,
        select: {venue.parser_module_name, venue.id}

    venue_ids = query |> Repo.all() |> Map.new()

    case parser_module_names -- Map.keys(venue_ids) do
      [] ->
        :ok

      missing ->
        # A venue rename would otherwise silently drop that venue's coverage.
        Logger.warning("TicketNetwork: no venue found for #{Enum.join(missing, ", ")}")
    end

    venue_ids
  end

  defp venue_names do
    query = from venue in Venue, select: {venue.id, venue.name}

    query |> Repo.all() |> Map.new()
  end

  defp upcoming_events(venue_ids, today) do
    query =
      from event in Event,
        where: event.venue_id in ^venue_ids and event.date >= ^today and is_nil(event.deleted_at)

    Repo.all(query)
  end
end
