defmodule MusicListings.AnalyticsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Analytics
  alias MusicListings.Analytics.TelemetryHandler
  alias MusicListingsSchema.AnalyticsEvent

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

  describe "weekly_rail_traction/1" do
    test "buckets events into trailing and prior 7-day windows" do
      reference = ~U[2024-08-01 12:00:00Z]

      # this week: [2024-07-25 12:00, 2024-08-01 12:00)
      record_at("new_this_week.shown", ~U[2024-07-26 12:00:00Z])
      record_at("new_this_week.shown", ~U[2024-07-30 12:00:00Z])
      record_at("new_this_week.card_click", ~U[2024-07-30 12:00:00Z])

      # prior week: [2024-07-18 12:00, 2024-07-25 12:00)
      record_at("new_this_week.shown", ~U[2024-07-20 12:00:00Z])

      # outside both windows
      record_at("new_this_week.shown", ~U[2024-07-10 12:00:00Z])

      report = Analytics.weekly_rail_traction(reference)

      assert report.period_end == reference
      assert report.this_week_start == ~U[2024-07-25 12:00:00Z]
      assert report.prior_week_start == ~U[2024-07-18 12:00:00Z]
      assert report.this_week == %{"new_this_week.shown" => 2, "new_this_week.card_click" => 1}
      assert report.prior_week == %{"new_this_week.shown" => 1}
    end
  end

  describe "telemetry handler persists rows" do
    test "shown event records an impression row" do
      TelemetryHandler.handle_event(
        [:music_listings, :new_this_week, :shown],
        %{},
        %{},
        nil
      )

      assert [%AnalyticsEvent{name: "new_this_week.shown", metadata: %{}}] =
               Repo.all(AnalyticsEvent)
    end

    test "card_click event stores the event id" do
      TelemetryHandler.handle_event(
        [:music_listings, :new_this_week, :card_click],
        %{},
        %{event_id: "42"},
        nil
      )

      assert [%AnalyticsEvent{name: "new_this_week.card_click", metadata: %{"event_id" => "42"}}] =
               Repo.all(AnalyticsEvent)
    end

    test "ticket_click event stores the event id" do
      TelemetryHandler.handle_event(
        [:music_listings, :new_this_week, :ticket_click],
        %{},
        %{event_id: "42"},
        nil
      )

      assert [
               %AnalyticsEvent{
                 name: "new_this_week.ticket_click",
                 metadata: %{"event_id" => "42"}
               }
             ] = Repo.all(AnalyticsEvent)
    end
  end

  # Inserts an analytics event stamped at a specific `inserted_at` (record_event/2
  # always stamps "now", so we set the timestamp explicitly for window tests).
  defp record_at(name, %DateTime{} = inserted_at) do
    Repo.insert!(%AnalyticsEvent{name: name, metadata: %{}, inserted_at: inserted_at})
  end
end
