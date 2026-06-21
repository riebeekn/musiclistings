defmodule MusicListings.ParserHealthTest do
  use MusicListings.DataCase, async: true

  import MusicListings.Factory

  alias MusicListings.ParserHealth
  alias MusicListingsSchema.VenueCrawlSummary

  @reference ~U[2024-08-01 12:00:00Z]

  # Records a crawl `days_ago` before the reference, with a per-venue yield split
  # across new/updated/duplicate (sum == yield) plus optional errors.
  defp crawl(venue, days_ago, yield, errors \\ 0) do
    completed_at = DateTime.add(@reference, -days_ago, :day)
    crawl_summary = insert(:crawl_summary, completed_at: completed_at)

    Repo.insert!(%VenueCrawlSummary{
      venue_id: venue.id,
      crawl_summary_id: crawl_summary.id,
      new: yield,
      updated: 0,
      duplicate: 0,
      ignored: 0,
      errors: errors
    })
  end

  describe "pullback_report/1" do
    test "flags a venue whose recent yield collapsed below its baseline" do
      venue = insert(:venue, name: "Phoenix")

      # Healthy baseline ~20/crawl for a couple weeks...
      for days_ago <- 4..17, do: crawl(venue, days_ago, 20)
      # ...then the last 3 crawls go silent (0 events, no errors).
      for days_ago <- 1..3, do: crawl(venue, days_ago, 0)

      report = ParserHealth.pullback_report(@reference)

      assert report.evaluated_count == 1
      assert report.healthy_count == 0
      assert [flagged] = report.flagged
      assert flagged.venue_name == "Phoenix"
      assert flagged.baseline_yield == 20
      assert flagged.recent_yield == 0.0
      assert flagged.drop_pct == 1.0
      assert flagged.recent_errors == 0
    end

    test "does not flag a venue crawling within its normal range" do
      venue = insert(:venue, name: "Drake")

      for days_ago <- 1..17, do: crawl(venue, days_ago, 18)

      report = ParserHealth.pullback_report(@reference)

      assert report.evaluated_count == 1
      assert report.flagged == []
    end

    test "does not flag naturally tiny venues below the baseline floor" do
      venue = insert(:venue, name: "Tiny Room")

      # Typically 2 events, drops to 0 — below the min-baseline-yield floor.
      for days_ago <- 4..17, do: crawl(venue, days_ago, 2)
      for days_ago <- 1..3, do: crawl(venue, days_ago, 0)

      report = ParserHealth.pullback_report(@reference)

      assert report.flagged == []
    end

    test "skips venues without enough history to judge" do
      venue = insert(:venue, name: "New Venue")

      # Only 3 crawls total — not enough baseline.
      for days_ago <- 1..3, do: crawl(venue, days_ago, 20)

      report = ParserHealth.pullback_report(@reference)

      assert report.evaluated_count == 0
      assert report.flagged == []
    end

    test "ignores crawls outside the lookback window and inactive venues" do
      active = insert(:venue, name: "Active")
      inactive = insert(:venue, name: "Inactive", pull_events?: false)

      # Active venue: healthy baseline then a pullback, but with an old crawl that
      # should be excluded from the window.
      crawl(active, 60, 999)
      for days_ago <- 4..17, do: crawl(active, days_ago, 20)
      for days_ago <- 1..3, do: crawl(active, days_ago, 0)

      # Inactive venue would look pulled-back but must not be evaluated.
      for days_ago <- 4..17, do: crawl(inactive, days_ago, 30)
      for days_ago <- 1..3, do: crawl(inactive, days_ago, 0)

      report = ParserHealth.pullback_report(@reference)

      assert report.evaluated_count == 1
      assert [flagged] = report.flagged
      assert flagged.venue_name == "Active"
      assert flagged.baseline_yield == 20
    end
  end
end
