defmodule Mix.Tasks.RekeyHistoryEventsTest do
  use MusicListings.DataCase, async: true

  alias Mix.Tasks.RekeyHistoryEvents
  alias MusicListings.Parsing.VenueParsers.HistoryParser
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue

  setup do
    live_nation_events =
      "#{File.cwd!()}/test/data/history/index.json"
      |> File.read!()
      |> HistoryParser.events()

    %{venue: Repo.get_by!(Venue, name: "History"), live_nation_events: live_nation_events}
  end

  describe "rekey/3" do
    test "moves an event stored under its title and date id onto its Live Nation id", %{
      venue: venue,
      live_nation_events: live_nation_events
    } do
      event = insert(:event, venue: venue, external_id: "kettama_2026_10_31")

      RekeyHistoryEvents.rekey(venue, live_nation_events, true)

      assert %Event{external_id: "177Zv0G653rShzz"} = Repo.reload!(event)
    end

    test "moves each night of a run onto its own id", %{
      venue: venue,
      live_nation_events: live_nation_events
    } do
      first =
        insert(:event, venue: venue, external_id: "geese_getting_killed_again_tour_2026_11_03")

      second =
        insert(:event, venue: venue, external_id: "geese_getting_killed_again_tour_2026_11_04")

      RekeyHistoryEvents.rekey(venue, live_nation_events, true)

      assert "1A8Zk3fGkeJq_g9" == Repo.reload!(first).external_id
      assert "1A8Zk3fGkeJragO" == Repo.reload!(second).external_id
    end

    test "re-keys a soft-deleted event so it stays deleted", %{
      venue: venue,
      live_nation_events: live_nation_events
    } do
      event =
        insert(:event,
          venue: venue,
          external_id: "kettama_2026_10_31",
          deleted_at: ~U[2026-10-01 00:00:00Z]
        )

      RekeyHistoryEvents.rekey(venue, live_nation_events, true)

      assert %Event{external_id: "177Zv0G653rShzz"} = Repo.reload!(event)
    end

    test "writes nothing on a dry run", %{venue: venue, live_nation_events: live_nation_events} do
      event = insert(:event, venue: venue, external_id: "kettama_2026_10_31")

      %{results: results} = RekeyHistoryEvents.rekey(venue, live_nation_events, false)

      assert [{:rekey, _event, "177Zv0G653rShzz"}] = results[:rekey]
      assert "kettama_2026_10_31" == Repo.reload!(event).external_id
    end

    test "leaves an event stored under both ids alone", %{
      venue: venue,
      live_nation_events: live_nation_events
    } do
      old = insert(:event, venue: venue, external_id: "kettama_2026_10_31")
      insert(:event, venue: venue, external_id: "177Zv0G653rShzz")

      %{results: results} = RekeyHistoryEvents.rekey(venue, live_nation_events, true)

      assert [{:conflict, _event, "177Zv0G653rShzz"}] = results[:conflict]
      assert "kettama_2026_10_31" == Repo.reload!(old).external_id
    end

    test "leaves alone two shows that rebuild the same old id", %{venue: venue} do
      [kettama | _rest] =
        "#{File.cwd!()}/test/data/history/single_event.json"
        |> File.read!()
        |> HistoryParser.events()

      late_show = Map.put(kettama, "discovery_id", "late_show")
      event = insert(:event, venue: venue, external_id: "kettama_2026_10_31")

      %{results: results} = RekeyHistoryEvents.rekey(venue, [kettama, late_show], true)

      assert 2 == length(results[:ambiguous])
      assert "kettama_2026_10_31" == Repo.reload!(event).external_id
    end

    test "only touches the given venue's events", %{
      venue: venue,
      live_nation_events: live_nation_events
    } do
      other = insert(:event, external_id: "kettama_2026_10_31")

      RekeyHistoryEvents.rekey(venue, live_nation_events, true)

      assert "kettama_2026_10_31" == Repo.reload!(other).external_id
    end

    test "reports upcoming stored events no Live Nation event matched", %{
      venue: venue,
      live_nation_events: live_nation_events
    } do
      renamed =
        insert(:event, venue: venue, external_id: "kettama_live_2026_10_31", date: ~D[2026-10-31])

      insert(:event, venue: venue, external_id: "long_gone_2024_01_01", date: ~D[2024-01-01])

      insert(:event,
        venue: venue,
        external_id: "deleted_2026_10_31",
        date: ~D[2026-10-31],
        deleted_at: ~U[2026-10-01 00:00:00Z]
      )

      %{unmatched: unmatched} = RekeyHistoryEvents.rekey(venue, live_nation_events, false)

      assert [renamed.id] == Enum.map(unmatched, & &1.id)
    end
  end
end
