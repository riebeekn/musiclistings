defmodule MusicListings.Analytics do
  @moduledoc """
  Context for first-party product analytics.

  Records lightweight, telemetry-driven events (impressions, clicks) to the
  `analytics_events` table. Events are emitted via `:telemetry` at the call
  sites and persisted by `MusicListings.Analytics.TelemetryHandler`, keeping
  the measurement layer decoupled from any particular storage or vendor.
  """
  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListingsSchema.AnalyticsEvent
  alias MusicListingsUtilities.DateHelpers

  @doc """
  Persists a single analytics event identified by `name`, with an optional
  free-form `metadata` map.
  """
  @spec record_event(String.t(), map()) ::
          {:ok, AnalyticsEvent.t()} | {:error, Ecto.Changeset.t()}
  def record_event(name, metadata \\ %{}) when is_binary(name) and is_map(metadata) do
    %AnalyticsEvent{name: name, metadata: metadata}
    |> Repo.insert()
  end

  @doc """
  Returns a map of event name => total count. Handy for a quick read in IEx,
  e.g. `MusicListings.Analytics.counts()`.
  """
  @spec counts() :: %{optional(String.t()) => non_neg_integer()}
  def counts do
    AnalyticsEvent
    |> group_by([event], event.name)
    |> select([event], {event.name, count(event.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Like `counts/0`, but limited to events recorded in the half-open window
  `[from, to)`. Relies on the indexed `inserted_at` column, so it stays cheap
  even as the table grows.
  """
  @spec counts_between(DateTime.t(), DateTime.t()) ::
          %{optional(String.t()) => non_neg_integer()}
  def counts_between(%DateTime{} = from, %DateTime{} = to) do
    AnalyticsEvent
    |> where([event], event.inserted_at >= ^from and event.inserted_at < ^to)
    |> group_by([event], event.name)
    |> select([event], {event.name, count(event.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Like `counts_between/2`, but for a single event `name`, split by the value of
  the `ref` key in each event's `metadata`. Returns a map of `ref => count`
  (events with no `ref` are grouped under the `nil` key). Used to attribute
  `event.ticket_click`s to their referrer — e.g. how many came from the
  "New This Week" rail (`ref == "new_this_week"`) versus direct visits.
  """
  @spec ref_counts_between(String.t(), DateTime.t(), DateTime.t()) ::
          %{optional(String.t() | nil) => non_neg_integer()}
  def ref_counts_between(name, %DateTime{} = from, %DateTime{} = to) when is_binary(name) do
    AnalyticsEvent
    |> where([event], event.name == ^name)
    |> where([event], event.inserted_at >= ^from and event.inserted_at < ^to)
    |> group_by([event], fragment("?->>'ref'", event.metadata))
    |> select([event], {fragment("?->>'ref'", event.metadata), count(event.id)})
    |> Repo.all()
    |> Map.new()
  end

  # Matched case-insensitively against the recorded user agent. Rows whose user
  # agent is unknown (nil — every row written before visitor tracking shipped)
  # are kept: absence of evidence isn't evidence of a bot.
  @bot_user_agent_pattern "(bot|crawl|spider|slurp|headless|lighthouse|preview|monitor|curl|wget|python-requests|scrapy|axios|ahrefs|semrush|facebookexternalhit)"

  defp exclude_bots(query) do
    where(
      query,
      [event],
      is_nil(fragment("?->>'user_agent'", event.metadata)) or
        not fragment(
          "(?->>'user_agent') ~* ?",
          event.metadata,
          ^@bot_user_agent_pattern
        )
    )
  end

  @doc """
  Ticket-link impressions and ticket clicks for `[from, to)`, split by the
  surface the visit came from (`metadata->>'ref'`: `"new_this_week"`,
  `"listing"`, `"venue_page"`, or `nil` for search/direct landings).

  This is the comparison the rail actually has to win: a rail card click and a
  listing row click are both internal browse navigations, whereas the `nil`
  bucket is dominated by search engine arrivals that land on an event page
  already intending to buy. Comparing the rail against `nil` flatters the
  denominator and makes any browse surface look broken.

  Counts are **deduplicated per (visitor, event, day)** — the `?ref=` param
  persists in the URL, so a LiveView reconnect or a back/forward re-mounts the
  page and would otherwise re-fire the impression — and **exclude known bots**,
  which reach the detail page over a real socket and never buy a ticket. Rows
  predating visitor tracking have no `visitor_id`; they fall back to counting
  once each rather than collapsing into a single bucket.
  """
  @spec surface_funnel_between(DateTime.t(), DateTime.t()) :: %{
          optional(String.t() | nil) => %{shown: non_neg_integer(), clicks: non_neg_integer()}
        }
  def surface_funnel_between(%DateTime{} = from, %DateTime{} = to) do
    shown = deduped_ref_counts("event.ticket_link_shown", from, to)
    clicks = deduped_ref_counts("event.ticket_click", from, to)

    shown
    |> Map.keys()
    |> Enum.concat(Map.keys(clicks))
    |> Enum.uniq()
    |> Map.new(fn ref ->
      {ref, %{shown: Map.get(shown, ref, 0), clicks: Map.get(clicks, ref, 0)}}
    end)
  end

  defp deduped_ref_counts(name, from, to) do
    AnalyticsEvent
    |> where([event], event.name == ^name)
    |> where([event], event.inserted_at >= ^from and event.inserted_at < ^to)
    |> exclude_bots()
    |> group_by([event], fragment("?->>'ref'", event.metadata))
    |> select(
      [event],
      {fragment("?->>'ref'", event.metadata),
       count(
         fragment(
           "coalesce(?->>'visitor_id', ?::text) || '|' || coalesce(?->>'event_id', '') || '|' || (?)::date::text",
           event.metadata,
           event.id,
           event.metadata,
           event.inserted_at
         ),
         :distinct
       )}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Builds the data for the weekly "New This Week" rail traction email: event
  counts for the trailing 7 days (`this_week`) alongside the preceding 7 days
  (`prior_week`) for a period-over-period comparison. Windows are rolling
  (relative to `reference`), not calendar-aligned.

  `*_conversions` hold `event.ticket_click` counts split by referrer (see
  `ref_counts_between/3`) so the email can report the rail conversion funnel
  (card click on the rail → ticket click on the detail page). `*_ticket_shown`
  hold `event.ticket_link_shown` counts split by referrer, giving the fair
  conversion denominator: rail visits that actually had a ticket link to click
  (a card click on an event with no ticket link can never convert).
  """
  @spec weekly_rail_traction(DateTime.t()) :: %{
          period_end: DateTime.t(),
          this_week_start: DateTime.t(),
          prior_week_start: DateTime.t(),
          this_week: %{optional(String.t()) => non_neg_integer()},
          prior_week: %{optional(String.t()) => non_neg_integer()},
          this_week_conversions: %{optional(String.t() | nil) => non_neg_integer()},
          prior_week_conversions: %{optional(String.t() | nil) => non_neg_integer()},
          this_week_ticket_shown: %{optional(String.t() | nil) => non_neg_integer()},
          prior_week_ticket_shown: %{optional(String.t() | nil) => non_neg_integer()},
          this_week_surfaces: %{
            optional(String.t() | nil) => %{shown: non_neg_integer(), clicks: non_neg_integer()}
          }
        }
  def weekly_rail_traction(reference \\ DateHelpers.now()) do
    this_week_start = DateTime.add(reference, -7, :day)
    prior_week_start = DateTime.add(reference, -14, :day)

    %{
      period_end: reference,
      this_week_start: this_week_start,
      prior_week_start: prior_week_start,
      this_week: counts_between(this_week_start, reference),
      prior_week: counts_between(prior_week_start, this_week_start),
      this_week_conversions: ref_counts_between("event.ticket_click", this_week_start, reference),
      prior_week_conversions:
        ref_counts_between("event.ticket_click", prior_week_start, this_week_start),
      this_week_ticket_shown:
        ref_counts_between("event.ticket_link_shown", this_week_start, reference),
      prior_week_ticket_shown:
        ref_counts_between("event.ticket_link_shown", prior_week_start, this_week_start),
      this_week_surfaces: surface_funnel_between(this_week_start, reference)
    }
  end
end
