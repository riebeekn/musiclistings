defmodule MusicListings.Events.RecentlyAddedRanker do
  @moduledoc """
  Ranks recently added events for the "Recently Added" feed.

  The crawler sets `inserted_at` once, when an event is first discovered, and never
  touches it on re-crawl - so it is a stable signal for "newly added". A naive
  `order by inserted_at desc` has three problems this ranker addresses:

    1. A newly onboarded venue (or one that finally adds its backlog) inserts all of
       its events in a single crawl run, which would otherwise flood the feed.
    2. Bigger shows - proxied by the presence of a ticket link - should lead.
    3. Smaller / free shows must still appear; the nudges above should not exclude them.

  Recency strictly dominates the ordering. The dominant sort key is the **Eastern calendar
  day** of a show's `inserted_at`: everything added on a later day ranks above everything
  added earlier, no matter what. The ticket boost and the venue diversity decay are purely
  secondary - they only order shows *within* a single day bucket and can never move a show
  across days. A hard per-venue cap (not the gentle score decay) is what guarantees no
  single venue dominates.

  This module is pure: `now` is passed in for API symmetry but ordering is independent of it
  (the calendar-day bucket is absolute), so results are deterministic and testable without
  touching the database (event `inserted_at` is otherwise auto-generated).
  """

  alias MusicListingsSchema.Event
  alias MusicListingsUtilities.DateHelpers

  @default_ticket_boost 0.35
  @default_diversity_decay 0.85
  @default_max_per_venue 3
  @default_limit 30

  @type rank_opt ::
          {:ticket_boost, number()}
          | {:diversity_decay, number()}
          | {:max_per_venue, pos_integer()}
          | {:limit, pos_integer()}

  @typep show :: %{
           venue_id: pos_integer(),
           id: pos_integer() | nil,
           inserted_at: DateTime.t(),
           has_ticket?: boolean(),
           events: [Event.t()]
         }

  @doc """
  Ranks candidate events for the recently added feed.

  Pure function - `now` is supplied by the caller so the result is deterministic.

  A show (same venue/title) is collapsed into a single ranked slot even when it recurs on
  multiple dates - only the soonest upcoming occurrence's events are returned, so each show
  appears once. The returned list is the underlying events of the selected shows, in ranked
  order, with each show's events kept contiguous (the caller relies on this to rebuild one
  item per show). The `:venue` association is expected to be preloaded and is preserved on
  the returned events.
  """
  @spec rank([Event.t()], DateTime.t(), [rank_opt]) :: [Event.t()]
  def rank(events, now, opts \\ [])

  def rank([], _now, _opts), do: []

  def rank(events, _now, opts) do
    ticket_boost = Keyword.get(opts, :ticket_boost, @default_ticket_boost)
    diversity_decay = Keyword.get(opts, :diversity_decay, @default_diversity_decay)
    max_per_venue = Keyword.get(opts, :max_per_venue, @default_max_per_venue)
    limit = Keyword.get(opts, :limit, @default_limit)

    events
    |> collapse_to_shows()
    |> Enum.map(fn show -> {show, base_score(show, ticket_boost)} end)
    |> sort_scored()
    |> apply_diversity_decay(diversity_decay)
    |> sort_scored()
    |> select_with_cap(max_per_venue, limit)
    |> Enum.flat_map(& &1.events)
  end

  # Collapse events into shows keyed by {venue_id, title} so a recurring show that runs on
  # several dates occupies a single slot in the feed (it is "one event" to the reader). The
  # slot represents the soonest upcoming occurrence: only that date's events are carried
  # forward, so the card shows a single date and its showtimes. A show is "first discovered"
  # at the earliest inserted_at across all of its occurrences, and counts as ticketed if the
  # displayed occurrence has a ticket url.
  @spec collapse_to_shows([Event.t()]) :: [show]
  defp collapse_to_shows(events) do
    events
    |> Enum.group_by(&{&1.venue_id, &1.title})
    |> Enum.map(fn {{venue_id, _title}, grouped_events} ->
      next_date = grouped_events |> Enum.map(& &1.date) |> Enum.min(Date)
      next_date_events = Enum.filter(grouped_events, &(&1.date == next_date))

      %{
        venue_id: venue_id,
        id: next_date_events |> Enum.map(& &1.id) |> Enum.min(),
        inserted_at: grouped_events |> Enum.map(& &1.inserted_at) |> Enum.min(DateTime),
        has_ticket?: Enum.any?(next_date_events, &(&1.ticket_url not in [nil, ""])),
        events: next_date_events
      }
    end)
  end

  # Quality score only - recency is handled separately as the dominant sort key
  # (see recency_bucket/1), so it must not be folded into this number.
  @spec base_score(show, number()) :: float()
  defp base_score(show, ticket_boost) do
    if show.has_ticket?, do: 1 + ticket_boost, else: 1.0
  end

  # Apply a soft per-venue geometric decay: the venue's k-th best show (0-based) is
  # multiplied by diversity_decay^k. This spreads near-ties so a venue's strongest show
  # leads; the hard cap below is what actually bounds domination.
  @spec apply_diversity_decay([{show, float()}], number()) :: [{show, float()}]
  defp apply_diversity_decay(scored_shows, diversity_decay) do
    {decayed, _counts} =
      Enum.map_reduce(scored_shows, %{}, fn {show, score}, counts ->
        k = Map.get(counts, show.venue_id, 0)
        {{show, score * :math.pow(diversity_decay, k)}, Map.put(counts, show.venue_id, k + 1)}
      end)

    decayed
  end

  # Walk shows best-first, emitting each unless its venue already hit max_per_venue;
  # stop once limit shows have been selected. This is the hard anti-domination guarantee.
  @spec select_with_cap([{show, float()}], pos_integer(), pos_integer()) :: [show]
  defp select_with_cap(scored_shows, max_per_venue, limit) do
    {selected, _counts, _taken} =
      Enum.reduce_while(scored_shows, {[], %{}, 0}, fn {show, _score}, {acc, counts, taken} ->
        venue_count = Map.get(counts, show.venue_id, 0)

        cond do
          taken >= limit ->
            {:halt, {acc, counts, taken}}

          venue_count >= max_per_venue ->
            {:cont, {acc, counts, taken}}

          true ->
            {:cont, {[show | acc], Map.put(counts, show.venue_id, venue_count + 1), taken + 1}}
        end
      end)

    Enum.reverse(selected)
  end

  # Sort by recency bucket first (the dominant key - a newer day always wins), then by
  # quality score, with deterministic tiebreakers (most-recent then highest id first) so
  # ordering is stable under the inevitable float-score ties.
  @spec sort_scored([{show, float()}]) :: [{show, float()}]
  defp sort_scored(scored_shows) do
    Enum.sort_by(
      scored_shows,
      fn {show, score} ->
        {recency_bucket(show), score, DateTime.to_unix(show.inserted_at), show.id}
      end,
      :desc
    )
  end

  # The dominant sort key: the Eastern calendar day of inserted_at as an integer
  # (gregorian days). An integer is required because comparing %Date{} structs inside a
  # tuple would use Erlang term order, which is not chronological.
  @spec recency_bucket(show) :: integer()
  defp recency_bucket(show) do
    show.inserted_at |> DateHelpers.to_eastern_date() |> Date.to_gregorian_days()
  end
end
