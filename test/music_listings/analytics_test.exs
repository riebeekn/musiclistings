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

  describe "ref_counts_between/3" do
    test "counts a single event name split by its metadata ref within the window" do
      record_at("event.ticket_click", ~U[2024-07-28 12:00:00Z], %{"ref" => "new_this_week"})
      record_at("event.ticket_click", ~U[2024-07-29 12:00:00Z], %{"ref" => "new_this_week"})
      record_at("event.ticket_click", ~U[2024-07-30 12:00:00Z], %{"ref" => nil})
      # different event name — ignored
      record_at("new_this_week.card_click", ~U[2024-07-30 12:00:00Z], %{})
      # outside the window — ignored
      record_at("event.ticket_click", ~U[2024-07-01 12:00:00Z], %{"ref" => "new_this_week"})

      counts =
        Analytics.ref_counts_between(
          "event.ticket_click",
          ~U[2024-07-25 00:00:00Z],
          ~U[2024-08-01 00:00:00Z]
        )

      assert counts == %{"new_this_week" => 2, nil => 1}
    end
  end

  describe "surface_funnel_between/2" do
    @window_from ~U[2024-07-25 00:00:00Z]
    @window_to ~U[2024-08-01 00:00:00Z]

    defp shown_at(at, metadata),
      do: record_at("event.ticket_link_shown", at, metadata)

    defp clicked_at(at, metadata),
      do: record_at("event.ticket_click", at, metadata)

    test "splits ticket CTR by the surface the visit came from" do
      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "new_this_week",
        "event_id" => "1",
        "visitor_id" => "v1"
      })

      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "listing",
        "event_id" => "2",
        "visitor_id" => "v2"
      })

      clicked_at(~U[2024-07-28 12:05:00Z], %{
        "ref" => "listing",
        "event_id" => "2",
        "visitor_id" => "v2"
      })

      assert Analytics.surface_funnel_between(@window_from, @window_to) == %{
               "new_this_week" => %{shown: 1, clicks: 0},
               "listing" => %{shown: 1, clicks: 1}
             }
    end

    test "dedupes repeat impressions from one visitor on one event in a day" do
      # The ?ref= param persists in the URL, so a LiveView reconnect or a
      # back/forward re-mounts the page and re-fires the impression. Counting
      # those would inflate the denominator and depress the surface's CTR.
      for _remount <- 1..5 do
        shown_at(~U[2024-07-28 12:00:00Z], %{
          "ref" => "new_this_week",
          "event_id" => "1",
          "visitor_id" => "v1"
        })
      end

      assert %{"new_this_week" => %{shown: 1}} =
               Analytics.surface_funnel_between(@window_from, @window_to)
    end

    test "counts distinct visitors and distinct events separately" do
      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "listing",
        "event_id" => "1",
        "visitor_id" => "v1"
      })

      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "listing",
        "event_id" => "1",
        "visitor_id" => "v2"
      })

      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "listing",
        "event_id" => "2",
        "visitor_id" => "v1"
      })

      assert %{"listing" => %{shown: 3}} =
               Analytics.surface_funnel_between(@window_from, @window_to)
    end

    test "excludes known bots, which reach the page over a real socket but never buy" do
      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "new_this_week",
        "event_id" => "1",
        "visitor_id" => "bot1",
        "user_agent" => "Mozilla/5.0 (compatible; SomeCrawler/2.1; +http://example.com/bot)"
      })

      shown_at(~U[2024-07-28 12:00:00Z], %{
        "ref" => "new_this_week",
        "event_id" => "2",
        "visitor_id" => "human",
        "user_agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/604.1"
      })

      assert %{"new_this_week" => %{shown: 1}} =
               Analytics.surface_funnel_between(@window_from, @window_to)
    end

    test "keeps rows recorded before visitor tracking shipped, counting each once" do
      # Historical rows have neither visitor_id nor user_agent. They must not
      # collapse into a single deduped row, nor be dropped as "not known human".
      for event_id <- ["1", "2", "3"] do
        shown_at(~U[2024-07-28 12:00:00Z], %{"ref" => "new_this_week", "event_id" => event_id})
      end

      assert %{"new_this_week" => %{shown: 3}} =
               Analytics.surface_funnel_between(@window_from, @window_to)
    end
  end

  describe "weekly_rail_traction/1" do
    test "buckets events into trailing and prior 7-day windows" do
      reference = ~U[2024-08-01 12:00:00Z]

      # this week: [2024-07-25 12:00, 2024-08-01 12:00)
      record_at("new_this_week.shown", ~U[2024-07-26 12:00:00Z])
      record_at("new_this_week.shown", ~U[2024-07-30 12:00:00Z])
      record_at("new_this_week.card_click", ~U[2024-07-30 12:00:00Z])
      record_at("event.ticket_link_shown", ~U[2024-07-30 12:00:00Z], %{"ref" => "new_this_week"})
      record_at("event.ticket_link_shown", ~U[2024-07-31 12:00:00Z], %{"ref" => nil})
      record_at("event.ticket_click", ~U[2024-07-30 12:00:00Z], %{"ref" => "new_this_week"})
      record_at("event.ticket_click", ~U[2024-07-31 12:00:00Z], %{"ref" => nil})

      # prior week: [2024-07-18 12:00, 2024-07-25 12:00)
      record_at("new_this_week.shown", ~U[2024-07-20 12:00:00Z])
      record_at("event.ticket_link_shown", ~U[2024-07-20 12:00:00Z], %{"ref" => "new_this_week"})
      record_at("event.ticket_click", ~U[2024-07-20 12:00:00Z], %{"ref" => "new_this_week"})

      # outside both windows
      record_at("new_this_week.shown", ~U[2024-07-10 12:00:00Z])

      report = Analytics.weekly_rail_traction(reference)

      assert report.period_end == reference
      assert report.this_week_start == ~U[2024-07-25 12:00:00Z]
      assert report.prior_week_start == ~U[2024-07-18 12:00:00Z]

      assert report.this_week == %{
               "new_this_week.shown" => 2,
               "new_this_week.card_click" => 1,
               "event.ticket_link_shown" => 2,
               "event.ticket_click" => 2
             }

      assert report.prior_week == %{
               "new_this_week.shown" => 1,
               "event.ticket_link_shown" => 1,
               "event.ticket_click" => 1
             }

      assert report.this_week_conversions == %{"new_this_week" => 1, nil => 1}
      assert report.prior_week_conversions == %{"new_this_week" => 1}
      assert report.this_week_ticket_shown == %{"new_this_week" => 1, nil => 1}
      assert report.prior_week_ticket_shown == %{"new_this_week" => 1}
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

    test "detail-page ticket_link_shown event stores the event id and ref" do
      TelemetryHandler.handle_event(
        [:music_listings, :event, :ticket_link_shown],
        %{},
        %{event_id: "42", ref: "new_this_week"},
        nil
      )

      assert [
               %AnalyticsEvent{
                 name: "event.ticket_link_shown",
                 metadata: %{"event_id" => "42", "ref" => "new_this_week"}
               }
             ] = Repo.all(AnalyticsEvent)
    end

    test "detail-page ticket_click event stores the event id and a nil ref for direct visits" do
      TelemetryHandler.handle_event(
        [:music_listings, :event, :ticket_click],
        %{},
        %{event_id: "42", ref: nil},
        nil
      )

      assert [
               %AnalyticsEvent{
                 name: "event.ticket_click",
                 metadata: %{"event_id" => "42", "ref" => nil}
               }
             ] = Repo.all(AnalyticsEvent)
    end
  end

  # Inserts an analytics event stamped at a specific `inserted_at` (record_event/2
  # always stamps "now", so we set the timestamp explicitly for window tests).
  defp record_at(name, %DateTime{} = inserted_at, metadata \\ %{}) do
    Repo.insert!(%AnalyticsEvent{name: name, metadata: metadata, inserted_at: inserted_at})
  end
end
