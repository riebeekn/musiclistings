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

  describe "telemetry handler persists rows" do
    test "shown event stores the count" do
      TelemetryHandler.handle_event(
        [:music_listings, :new_this_week, :shown],
        %{count: 7},
        %{},
        nil
      )

      assert [%AnalyticsEvent{name: "new_this_week.shown", metadata: %{"count" => 7}}] =
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
end
