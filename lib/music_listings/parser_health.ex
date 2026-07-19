defmodule MusicListings.ParserHealth do
  @moduledoc """
  Detects venues whose parser may have silently pulled back.

  Every crawl writes a `VenueCrawlSummary` row per venue; the crawler filters out
  no-date and past events *before* those stats are tallied, so a venue's
  `new + updated + duplicate` for a run ("yield") is the count of valid upcoming
  events the parser produced that crawl. When a parser breaks against a changed
  site, that yield collapses toward zero — often with no `errors`, which is the
  case the nightly crawl email does not surface.

  `pullback_report/1` compares each active venue's recent yield against its own
  historical baseline and flags meaningful drops. The thresholds below are
  deliberately conservative to keep the signal low-noise; tune as needed.
  """
  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Venue
  alias MusicListingsSchema.VenueCrawlSummary
  alias MusicListingsUtilities.DateHelpers

  # How far back to pull crawl history.
  @lookback_days 35
  # Number of most-recent crawls treated as "current".
  @recent_crawls 3
  # A venue needs at least this many baseline crawls to be evaluated at all.
  @min_baseline_crawls 5
  # Ignore venues that are typically tiny — a drop there is not worth paging on.
  @min_baseline_yield 4
  # Flag when recent yield falls to this fraction (or less) of the baseline.
  @drop_ratio 0.4

  @type flagged_venue :: %{
          venue_name: String.t(),
          venue_website: String.t() | nil,
          baseline_yield: number(),
          recent_yield: number(),
          drop_pct: float(),
          recent_errors: non_neg_integer(),
          last_crawled_at: DateTime.t()
        }

  @type report :: %{
          reference: DateTime.t(),
          lookback_days: pos_integer(),
          recent_crawls: pos_integer(),
          evaluated_count: non_neg_integer(),
          healthy_count: non_neg_integer(),
          flagged: [flagged_venue()],
          awaiting: [String.t()],
          awaiting_count: non_neg_integer()
        }

  @doc """
  Builds the parser-pullback report for active (`pull_events?`) venues.
  """
  @spec pullback_report(DateTime.t()) :: report()
  def pullback_report(reference \\ DateHelpers.now()) do
    window_start = DateTime.add(reference, -@lookback_days, :day)

    evaluated =
      window_start
      |> fetch_rows(reference)
      |> Enum.group_by(& &1.venue_id)
      |> Enum.map(fn {venue_id, rows} -> {venue_id, analyze(rows)} end)
      |> Enum.reject(fn {_venue_id, analysis} -> is_nil(analysis) end)

    evaluated_ids = MapSet.new(evaluated, fn {venue_id, _analysis} -> venue_id end)
    analyses = Enum.map(evaluated, fn {_venue_id, analysis} -> analysis end)

    # Active venues we couldn't evaluate yet — no crawls in the window, or not
    # enough of them to establish a baseline. These are the difference between
    # the venue index count and the evaluated count.
    awaiting =
      fetch_active_venues()
      |> Enum.reject(&MapSet.member?(evaluated_ids, &1.id))
      |> Enum.map(& &1.name)
      |> Enum.sort()

    flagged =
      analyses
      |> Enum.filter(& &1.flagged?)
      |> Enum.map(&Map.delete(&1, :flagged?))
      |> Enum.sort_by(&{-&1.drop_pct, &1.recent_yield})

    %{
      reference: reference,
      lookback_days: @lookback_days,
      recent_crawls: @recent_crawls,
      evaluated_count: length(analyses),
      healthy_count: length(analyses) - length(flagged),
      flagged: flagged,
      awaiting: awaiting,
      awaiting_count: length(awaiting)
    }
  end

  defp fetch_rows(window_start, reference) do
    from(vcs in VenueCrawlSummary,
      join: cs in CrawlSummary,
      on: cs.id == vcs.crawl_summary_id,
      join: v in Venue,
      on: v.id == vcs.venue_id,
      where:
        v.pull_events? and not is_nil(cs.completed_at) and
          cs.completed_at >= ^window_start and cs.completed_at <= ^reference,
      select: %{
        venue_id: vcs.venue_id,
        venue_name: v.name,
        venue_website: v.website,
        yield: vcs.new + vcs.updated + vcs.duplicate,
        errors: vcs.errors,
        crawled_at: cs.completed_at
      }
    )
    |> Repo.all()
  end

  defp fetch_active_venues do
    from(v in Venue, where: v.pull_events?, select: %{id: v.id, name: v.name})
    |> Repo.all()
  end

  # Returns nil when a venue has too little history to judge.
  defp analyze(rows) do
    sorted = Enum.sort_by(rows, & &1.crawled_at, DateTime)
    {baseline, recent} = Enum.split(sorted, -@recent_crawls)

    if length(baseline) >= @min_baseline_crawls and recent != [] do
      baseline_yield = median(Enum.map(baseline, & &1.yield))
      recent_yield = mean(Enum.map(recent, & &1.yield))

      %{
        venue_name: hd(sorted).venue_name,
        venue_website: hd(sorted).venue_website,
        baseline_yield: baseline_yield,
        recent_yield: recent_yield,
        drop_pct: drop_pct(baseline_yield, recent_yield),
        recent_errors: recent |> Enum.map(& &1.errors) |> Enum.sum(),
        last_crawled_at: List.last(sorted).crawled_at,
        flagged?:
          baseline_yield >= @min_baseline_yield and
            recent_yield <= baseline_yield * @drop_ratio
      }
    end
  end

  defp drop_pct(baseline, _recent) when baseline <= 0, do: 0.0
  defp drop_pct(baseline, recent), do: (baseline - recent) / baseline

  defp mean([]), do: 0
  defp mean(values), do: Enum.sum(values) / length(values)

  defp median([]), do: 0

  defp median(values) do
    sorted = Enum.sort(values)
    count = length(sorted)
    mid = div(count, 2)

    if rem(count, 2) == 1 do
      Enum.at(sorted, mid)
    else
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    end
  end
end
