defmodule MusicListings.Analytics do
  @moduledoc """
  Context for first-party product analytics.

  Records lightweight, telemetry-driven events (impressions, clicks) to the
  `analytics_events` table. Events are emitted via `:telemetry` at the call
  sites and persisted by `MusicListings.Analytics.TelemetryHandler`, keeping
  the measurement layer decoupled from any particular storage or vendor.
  """
  import Ecto.Query

  alias MusicListings.Events
  alias MusicListings.Repo
  alias MusicListingsSchema.AnalyticsEvent
  alias MusicListingsSchema.Event
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

  @ticket_click "event.ticket_click"
  @ticket_link_shown "event.ticket_link_shown"
  @coverage_snapshot "weekly.ticket_coverage"
  @baseline_weeks 4
  @top_n 5
  # A venue is listed as losing ticket links when its coverage falls by at least
  # this much since the last report...
  @coverage_drop_threshold 0.10
  # ...and it had at least this many upcoming events both times. Below that, one
  # newly listed show without a link yet swings the rate by tens of points.
  @coverage_drop_min_events 5

  @type ticket_counts :: %{clicks: number(), impressions: number()}
  @type coverage :: %{total: non_neg_integer(), with_ticket_link: non_neg_integer()}
  @type venue_coverage :: %{
          venue_id: integer(),
          venue_name: String.t(),
          total: non_neg_integer(),
          with_ticket_link: non_neg_integer()
        }
  @type coverage_drop :: %{venue_name: String.t(), prior: coverage(), current: coverage()}

  @doc """
  Builds the data for the weekly engagement email, built on the event page's
  ticket button: clicks (`event.ticket_click`) and impressions
  (`event.ticket_link_shown`, recorded only when the event has a ticket link).

  - `this_week` / `prior_week` - totals for the trailing 7 days and the 7 days
    before that. Windows are rolling (relative to `reference`), not
    calendar-aligned.
  - `baseline` - weekly averages over the `baseline_weeks` weeks before this
    week. A single week-over-week comparison is mostly noise at these volumes;
    this gives a steadier reference point.
  - `top_venues` / `top_events` - this week's ticket clicks, joined back to the
    clicked event and its venue (deleted events still count - the click
    happened).
  - `ticket_coverage` - how many upcoming events carry a ticket link, right now.
    It is a point-in-time count, so `prior_ticket_coverage` is the snapshot the
    previous report saved (see `record_ticket_coverage/2`), or `nil` if there
    isn't one yet.
  - `ticket_coverage_by_venue` - the same count per venue, saved with the
    snapshot.
  - `coverage_drops` - venues whose coverage fell by at least
    `coverage_drop_threshold` (as a fraction) since that snapshot, biggest fall
    first. A drop like that usually means the venue's parser stopped picking up
    ticket links. Venues with fewer than #{@coverage_drop_min_events} upcoming
    events in either count are skipped as too noisy. `nil` when the prior
    snapshot has no per-venue counts (snapshots saved before they were added).
  """
  @spec weekly_engagement(DateTime.t()) :: %{
          period_end: DateTime.t(),
          this_week_start: DateTime.t(),
          prior_week_start: DateTime.t(),
          this_week: ticket_counts(),
          prior_week: ticket_counts(),
          baseline: ticket_counts(),
          baseline_weeks: pos_integer(),
          top_venues: [%{venue_name: String.t(), clicks: non_neg_integer()}],
          top_events: [
            %{
              id: integer(),
              title: String.t(),
              date: Date.t(),
              venue_name: String.t(),
              clicks: non_neg_integer()
            }
          ],
          ticket_coverage: coverage(),
          prior_ticket_coverage: coverage() | nil,
          ticket_coverage_by_venue: [venue_coverage()],
          coverage_drops: [coverage_drop()] | nil,
          coverage_drop_threshold: float()
        }
  def weekly_engagement(reference \\ DateHelpers.now()) do
    this_week_start = DateTime.add(reference, -7, :day)
    prior_week_start = DateTime.add(reference, -14, :day)
    baseline_start = DateTime.add(this_week_start, -7 * @baseline_weeks, :day)
    by_venue = Events.ticket_link_coverage_by_venue()

    # Any snapshot less than six days old was saved by a retry of this same
    # report, not by last week's, so look for one older than that.
    prior_snapshot = latest_ticket_coverage_before(DateTime.add(reference, -6, :day))

    %{
      period_end: reference,
      this_week_start: this_week_start,
      prior_week_start: prior_week_start,
      this_week: ticket_counts_between(this_week_start, reference),
      prior_week: ticket_counts_between(prior_week_start, this_week_start),
      baseline: weekly_average(baseline_start, this_week_start),
      baseline_weeks: @baseline_weeks,
      top_venues: top_venues_by_ticket_clicks(this_week_start, reference),
      top_events: top_events_by_ticket_clicks(this_week_start, reference),
      ticket_coverage: Events.ticket_link_coverage(),
      prior_ticket_coverage: prior_snapshot && prior_snapshot.coverage,
      ticket_coverage_by_venue: by_venue,
      coverage_drops: prior_snapshot && coverage_drops(prior_snapshot.by_venue, by_venue),
      coverage_drop_threshold: @coverage_drop_threshold
    }
  end

  @doc """
  Saves the ticket-link coverage a weekly report was sent with, overall and per
  venue, so the next report can show how it changed (coverage is current state,
  so it can't be reconstructed for a past date). Venues are keyed by id, so a
  renamed venue still lines up.
  """
  @spec record_ticket_coverage(coverage(), [venue_coverage()]) ::
          {:ok, AnalyticsEvent.t()} | {:error, Ecto.Changeset.t()}
  def record_ticket_coverage(%{total: total, with_ticket_link: with_ticket_link}, by_venue) do
    venues =
      Map.new(by_venue, fn venue ->
        {to_string(venue.venue_id),
         %{"total" => venue.total, "with_ticket_link" => venue.with_ticket_link}}
      end)

    record_event(@coverage_snapshot, %{
      "total" => total,
      "with_ticket_link" => with_ticket_link,
      "venues" => venues
    })
  end

  defp ticket_counts_between(from, to) do
    counts = counts_between(from, to)

    %{
      clicks: Map.get(counts, @ticket_click, 0),
      impressions: Map.get(counts, @ticket_link_shown, 0)
    }
  end

  defp weekly_average(from, to) do
    %{clicks: clicks, impressions: impressions} = ticket_counts_between(from, to)
    %{clicks: clicks / @baseline_weeks, impressions: impressions / @baseline_weeks}
  end

  defp top_venues_by_ticket_clicks(from, to) do
    from
    |> ticket_clicks_with_events(to)
    |> group_by([_click, _event, venue], [venue.id, venue.name])
    |> select([click, _event, venue], %{venue_name: venue.name, clicks: count(click.id)})
    |> order_by([click, _event, venue], desc: count(click.id), asc: venue.name)
    |> limit(@top_n)
    |> Repo.all()
  end

  defp top_events_by_ticket_clicks(from, to) do
    from
    |> ticket_clicks_with_events(to)
    |> group_by([_click, event, venue], [event.id, venue.name])
    |> select([click, event, venue], %{
      id: event.id,
      title: event.title,
      date: event.date,
      venue_name: venue.name,
      clicks: count(click.id)
    })
    |> order_by([click, event], desc: count(click.id), asc: event.date, asc: event.title)
    |> limit(@top_n)
    |> Repo.all()
  end

  # The event id comes from the client (a phx-value), so it's compared as text
  # rather than cast - a malformed id just fails to match instead of raising.
  defp ticket_clicks_with_events(from, to) do
    AnalyticsEvent
    |> where([click], click.name == @ticket_click)
    |> where([click], click.inserted_at >= ^from and click.inserted_at < ^to)
    |> join(:inner, [click], event in Event,
      on: fragment("?::text", event.id) == fragment("?->>'event_id'", click.metadata)
    )
    |> join(:inner, [_click, event], venue in assoc(event, :venue))
  end

  defp latest_ticket_coverage_before(cutoff) do
    AnalyticsEvent
    |> where([snapshot], snapshot.name == @coverage_snapshot)
    |> where([snapshot], snapshot.inserted_at < ^cutoff)
    |> order_by([snapshot], desc: snapshot.inserted_at, desc: snapshot.id)
    |> limit(1)
    |> Repo.one()
    |> case do
      %AnalyticsEvent{
        metadata: %{"total" => total, "with_ticket_link" => with_ticket_link} = metadata
      } ->
        %{
          coverage: %{total: total, with_ticket_link: with_ticket_link},
          by_venue: snapshot_venues(metadata)
        }

      _no_snapshot ->
        nil
    end
  end

  defp snapshot_venues(%{"venues" => venues}) do
    Map.new(venues, fn {venue_id, %{"total" => total, "with_ticket_link" => with_ticket_link}} ->
      {String.to_integer(venue_id), %{total: total, with_ticket_link: with_ticket_link}}
    end)
  end

  defp snapshot_venues(_snapshot_without_venues), do: nil

  defp coverage_drops(nil = _prior_by_venue, _current_by_venue), do: nil

  defp coverage_drops(prior_by_venue, current_by_venue) do
    current_by_venue
    |> Enum.flat_map(fn venue ->
      current = %{total: venue.total, with_ticket_link: venue.with_ticket_link}

      case Map.fetch(prior_by_venue, venue.venue_id) do
        {:ok, prior} -> [%{venue_name: venue.venue_name, prior: prior, current: current}]
        :error -> []
      end
    end)
    |> Enum.filter(fn %{prior: prior, current: current} ->
      prior.total >= @coverage_drop_min_events and current.total >= @coverage_drop_min_events and
        coverage_fall(prior, current) >= @coverage_drop_threshold
    end)
    |> Enum.sort_by(&coverage_fall(&1.prior, &1.current), :desc)
  end

  # Rounded so a fall of exactly the threshold (0.6 - 0.5 is 0.0999... as a
  # float) counts as reaching it.
  defp coverage_fall(prior, current) do
    Float.round(
      prior.with_ticket_link / prior.total - current.with_ticket_link / current.total,
      6
    )
  end
end
