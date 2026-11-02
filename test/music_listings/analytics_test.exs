defmodule MusicListings.AnalyticsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Analytics
  alias MusicListings.Analytics.TelemetryHandler
  alias MusicListingsSchema.AnalyticsEvent
  alias MusicListingsUtilities.DateHelpers

  describe "record_event/2" do
    test "inserts an event with the given name and metadata" do
      assert {:ok, %AnalyticsEvent{} = event} =
               Analytics.record_event("test.event", %{"key" => "value"})

      assert event.name == "test.event"
      assert event.metadata == %{"key" => "value"}
      assert event.inserted_at
    end

    test "defaults metadata to an empty map" do
      assert {:ok, %AnalyticsEvent{metadata: %{}}} = Analytics.record_event("test.event")
    end
  end

  describe "counts/0" do
    test "returns totals grouped by event name" do
      Analytics.record_event("a")
      Analytics.record_event("a")
      Analytics.record_event("b")

      assert Analytics.counts() == %{"a" => 2, "b" => 1}
    end

    test "returns an empty map when there are no events" do
      assert Analytics.counts() == %{}
    end
  end

  describe "counts_between/2" do
    test "only counts events recorded within the half-open window" do
      record_at("in.window", ~U[2024-07-28 12:00:00Z])
      record_at("in.window", ~U[2024-07-30 12:00:00Z])
      # exactly at `from` is included, exactly at `to` is excluded
      record_at("edge.from", ~U[2024-07-25 00:00:00Z])
      record_at("edge.to", ~U[2024-08-01 00:00:00Z])
      # outside the window
      record_at("before.window", ~U[2024-07-20 12:00:00Z])

      counts =
        Analytics.counts_between(~U[2024-07-25 00:00:00Z], ~U[2024-08-01 00:00:00Z])

      assert counts == %{"in.window" => 2, "edge.from" => 1}
    end

    test "returns an empty map when nothing falls in the window" do
      record_at("event", ~U[2024-07-01 12:00:00Z])

      assert Analytics.counts_between(~U[2024-07-25 00:00:00Z], ~U[2024-08-01 00:00:00Z]) ==
               %{}
    end
  end

  describe "weekly_engagement/1" do
    @reference ~U[2024-08-01 12:00:00Z]

    test "totals ticket clicks and impressions for the trailing and prior 7-day windows" do
      # this week: [2024-07-25 12:00, 2024-08-01 12:00)
      record_at("event.ticket_link_shown", ~U[2024-07-26 12:00:00Z])
      record_at("event.ticket_link_shown", ~U[2024-07-30 12:00:00Z])
      record_at("event.ticket_link_shown", ~U[2024-07-31 12:00:00Z])
      record_at("event.ticket_click", ~U[2024-07-30 12:00:00Z])
      # other event names are ignored
      record_at("new_this_week.card_click", ~U[2024-07-30 12:00:00Z])
      record_at("event.resale_click", ~U[2024-07-30 12:00:00Z])

      # prior week: [2024-07-18 12:00, 2024-07-25 12:00)
      record_at("event.ticket_link_shown", ~U[2024-07-20 12:00:00Z])
      record_at("event.ticket_click", ~U[2024-07-20 12:00:00Z])
      record_at("event.ticket_click", ~U[2024-07-25 11:59:59Z])

      report = Analytics.weekly_engagement(@reference)

      assert report.period_end == @reference
      assert report.this_week_start == ~U[2024-07-25 12:00:00Z]
      assert report.prior_week_start == ~U[2024-07-18 12:00:00Z]
      assert report.this_week == %{clicks: 1, impressions: 3}
      assert report.prior_week == %{clicks: 2, impressions: 1}
    end

    test "averages the four weeks before this week as a baseline" do
      # baseline: [2024-06-27 12:00, 2024-07-25 12:00)
      record_at("event.ticket_click", ~U[2024-06-27 12:00:00Z])
      record_at("event.ticket_click", ~U[2024-07-05 12:00:00Z])
      record_at("event.ticket_click", ~U[2024-07-20 12:00:00Z])
      for _impression <- 1..10, do: record_at("event.ticket_link_shown", ~U[2024-07-10 12:00:00Z])
      # before the baseline, and within this week - both excluded
      record_at("event.ticket_click", ~U[2024-06-27 11:59:59Z])
      record_at("event.ticket_click", ~U[2024-07-30 12:00:00Z])

      report = Analytics.weekly_engagement(@reference)

      assert report.baseline_weeks == 4
      assert report.baseline == %{clicks: 0.75, impressions: 2.5}
    end

    test "ranks this week's ticket clicks by venue and by event" do
      horseshoe = insert(:venue, name: "Venue A")
      lees = insert(:venue, name: "Venue B")
      headliner = insert(:event, venue: horseshoe, title: "Headliner", date: ~D[2024-08-10])
      opener = insert(:event, venue: horseshoe, title: "Opener", date: ~D[2024-08-05])
      indie = insert(:event, venue: lees, title: "Indie", date: ~D[2024-08-03])

      click(headliner, ~U[2024-07-30 12:00:00Z])
      click(headliner, ~U[2024-07-30 13:00:00Z])
      click(opener, ~U[2024-07-30 12:00:00Z])
      click(indie, ~U[2024-07-31 12:00:00Z])
      # prior week - not ranked
      click(indie, ~U[2024-07-20 12:00:00Z])
      click(indie, ~U[2024-07-20 13:00:00Z])
      # an id that matches no event (it comes from the client) is skipped, not raised on
      record_at("event.ticket_click", ~U[2024-07-30 12:00:00Z], %{"event_id" => "not-an-id"})

      report = Analytics.weekly_engagement(@reference)

      assert report.top_venues == [
               %{venue_name: "Venue A", clicks: 3},
               %{venue_name: "Venue B", clicks: 1}
             ]

      assert [
               %{title: "Headliner", venue_name: "Venue A", clicks: 2, date: ~D[2024-08-10]},
               # tied on clicks - the sooner show first
               %{title: "Indie", venue_name: "Venue B", clicks: 1},
               %{title: "Opener", venue_name: "Venue A", clicks: 1}
             ] = report.top_events

      assert hd(report.top_events).id == headliner.id
    end

    test "reports current ticket-link coverage of upcoming events" do
      insert(:event, date: ~D[2099-01-01])
      insert(:event, date: ~D[2099-01-02], ticket_url: nil)
      insert(:event, date: ~D[2099-01-03], ticket_url: "")
      # deleted or past - excluded
      insert(:event, date: ~D[2099-01-04], deleted_at: ~U[2024-07-01 00:00:00Z])
      insert(:event, date: ~D[2000-01-01])

      report = Analytics.weekly_engagement(@reference)

      assert report.ticket_coverage == %{total: 3, with_ticket_link: 1}
    end

    test "compares coverage against the last snapshot at least six days old" do
      record_at("weekly.ticket_coverage", ~U[2024-07-18 12:00:00Z], %{
        "total" => 100,
        "with_ticket_link" => 50
      })

      record_at("weekly.ticket_coverage", ~U[2024-07-25 12:00:00Z], %{
        "total" => 200,
        "with_ticket_link" => 150
      })

      # saved by a retry of this same report - ignored
      record_at("weekly.ticket_coverage", ~U[2024-08-01 11:00:00Z], %{
        "total" => 1,
        "with_ticket_link" => 1
      })

      report = Analytics.weekly_engagement(@reference)

      assert report.prior_ticket_coverage == %{total: 200, with_ticket_link: 150}
    end

    test "has no prior coverage before the first snapshot is saved" do
      assert Analytics.weekly_engagement(@reference).prior_ticket_coverage == nil
    end
  end

  describe "record_ticket_coverage/1" do
    test "saves a snapshot the next report reads back" do
      {:ok, _snapshot} = Analytics.record_ticket_coverage(%{total: 40, with_ticket_link: 30})

      next_week = DateTime.add(DateHelpers.now(), 7, :day)

      assert Analytics.weekly_engagement(next_week).prior_ticket_coverage ==
               %{total: 40, with_ticket_link: 30}
    end
  end

  describe "telemetry handler persists rows" do
    test "detail-page ticket_link_shown event stores the event id" do
      TelemetryHandler.handle_event(
        [:music_listings, :event, :ticket_link_shown],
        %{},
        %{event_id: "42"},
        nil
      )

      assert [
               %AnalyticsEvent{
                 name: "event.ticket_link_shown",
                 metadata: %{"event_id" => "42"}
               }
             ] = Repo.all(AnalyticsEvent)
    end

    test "detail-page ticket_click event stores the event id" do
      TelemetryHandler.handle_event(
        [:music_listings, :event, :ticket_click],
        %{},
        %{event_id: "42"},
        nil
      )

      assert [
               %AnalyticsEvent{
                 name: "event.ticket_click",
                 metadata: %{"event_id" => "42"}
               }
             ] = Repo.all(AnalyticsEvent)
    end
  end

  defp click(event, inserted_at) do
    record_at("event.ticket_click", inserted_at, %{"event_id" => to_string(event.id)})
  end

  # Inserts an analytics event stamped at a specific `inserted_at` (record_event/2
  # always stamps "now", so we set the timestamp explicitly for window tests).
  defp record_at(name, %DateTime{} = inserted_at, metadata \\ %{}) do
    Repo.insert!(%AnalyticsEvent{name: name, metadata: metadata, inserted_at: inserted_at})
  end
end
