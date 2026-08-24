defmodule MusicListings.EventsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Accounts.User
  alias MusicListings.Events
  alias MusicListings.Events.EventInfo
  alias MusicListings.Events.EventSuggestion
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Events.ShowTimeInfo
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsSchema.Venue
  alias MusicListingsUtilities.DateHelpers

  describe "list_events/1" do
    setup do
      venue_1 = insert(:venue)
      venue_2 = insert(:venue)
      insert(:event, venue: venue_1, date: ~D[2024-07-30], title: "ev0", time: ~T[18:00:00])
      insert(:event, venue: venue_1, date: ~D[2024-08-01], title: "ev1", time: ~T[19:00:00])
      insert(:event, venue: venue_2, date: ~D[2024-08-01], title: "ev2", time: ~T[20:00:00])
      insert(:event, venue: venue_2, date: ~D[2024-08-02], title: "ev3", time: ~T[12:00:00])

      insert(:event,
        venue: venue_2,
        date: ~D[2024-08-02],
        title: "ev4",
        deleted_at: DateTime.utc_now()
      )

      %{venue_1_id: venue_1.id, venue_2_id: venue_2.id}
    end

    test "lists events grouped by date, ignoring events in the past and deleted events", %{
      venue_1_id: venue_1_id,
      venue_2_id: venue_2_id
    } do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 {~D[2024-08-01],
                  [
                    %EventInfo{
                      title: "ev1",
                      date: ~D[2024-08-01],
                      venue: %Venue{id: ^venue_1_id},
                      showtimes: [%ShowTimeInfo{time: ~T[19:00:00]}]
                    },
                    %EventInfo{
                      title: "ev2",
                      date: ~D[2024-08-01],
                      venue: %Venue{id: ^venue_2_id},
                      showtimes: [%ShowTimeInfo{time: ~T[20:00:00]}]
                    }
                  ]},
                 {~D[2024-08-02],
                  [
                    %EventInfo{
                      title: "ev3",
                      date: ~D[2024-08-02],
                      venue: %Venue{id: ^venue_2_id},
                      showtimes: [%ShowTimeInfo{time: ~T[12:00:00]}]
                    }
                  ]}
               ]
             } = Events.list_events()
    end

    test "handles events with multiple showtimes for the same date" do
      Repo.delete_all(Event)
      e1 = insert(:event, date: ~D[2024-08-01], time: ~T[16:00:00], title: "ev5")
      e2 = insert(:event, date: ~D[2024-08-01], time: ~T[20:00:00], title: "ev5")
      e3 = insert(:event, date: ~D[2024-08-01], time: ~T[14:00:00], title: "ev5")

      e1_id = e1.id
      e2_id = e2.id
      e3_id = e3.id

      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 {~D[2024-08-01],
                  [
                    %EventInfo{
                      title: "ev5",
                      date: ~D[2024-08-01],
                      showtimes: [
                        %ShowTimeInfo{event_id: ^e3_id, time: ~T[14:00:00]},
                        %ShowTimeInfo{event_id: ^e1_id, time: ~T[16:00:00]},
                        %ShowTimeInfo{event_id: ^e2_id, time: ~T[20:00:00]}
                      ]
                    }
                  ]}
               ]
             } = Events.list_events()
    end

    test "groups a pre-dawn show under the previous night, leaving stored dates untouched" do
      Repo.delete_all(Event)
      venue = insert(:venue)
      insert(:event, venue: venue, date: ~D[2024-08-01], title: "Evening Set", time: ~T[22:00:00])
      # 2:30am on Aug 2 is the tail end of the Aug 1 night out
      late =
        insert(:event, venue: venue, date: ~D[2024-08-02], title: "Late Set", time: ~T[02:30:00])

      assert %PagedEvents{
               events: [
                 {~D[2024-08-01],
                  [
                    %EventInfo{title: "Evening Set", date: ~D[2024-08-01]},
                    %EventInfo{title: "Late Set", date: ~D[2024-08-01]}
                  ]}
               ]
             } = Events.list_events()

      # the stored record keeps its true calendar date
      assert ~D[2024-08-02] == Repo.reload(late).date
    end

    test "can filter by venue", %{venue_1_id: venue_1_id} do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 {~D[2024-08-01],
                  [
                    %EventInfo{
                      title: "ev1",
                      date: ~D[2024-08-01],
                      venue: %Venue{id: ^venue_1_id}
                    }
                  ]}
               ]
             } = Events.list_events(venue_ids: [venue_1_id])
    end

    test "can filter by from_date" do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 {~D[2024-08-02],
                  [
                    %EventInfo{
                      title: "ev3",
                      date: ~D[2024-08-02]
                    }
                  ]}
               ]
             } = Events.list_events(from_date: ~D[2024-08-02])
    end

    test "can combine venue filter and from_date filter", %{venue_2_id: venue_2_id} do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 {~D[2024-08-02],
                  [
                    %EventInfo{
                      title: "ev3",
                      date: ~D[2024-08-02],
                      venue: %Venue{id: ^venue_2_id}
                    }
                  ]}
               ]
             } = Events.list_events(venue_ids: [venue_2_id], from_date: ~D[2024-08-02])
    end

    test "from_date filters events starting from that date onwards" do
      # Should include ev1, ev2, and ev3
      assert %PagedEvents{
               events: [
                 {~D[2024-08-01], _events_on_aug_1},
                 {~D[2024-08-02], _events_on_aug_2}
               ]
             } = Events.list_events(from_date: ~D[2024-08-01])
    end

    test "from_date with nil behaves same as no filter" do
      result_with_nil = Events.list_events(from_date: nil)
      result_without = Events.list_events()

      assert result_with_nil.events == result_without.events
    end

    test "sorts events by title by default within a date group" do
      Repo.delete_all(Event)
      venue = insert(:venue, name: "Zebra Lounge")
      insert(:event, venue: venue, date: ~D[2024-08-01], title: "Charlie Band")
      insert(:event, venue: venue, date: ~D[2024-08-01], title: "Alpha Band")
      insert(:event, venue: venue, date: ~D[2024-08-01], title: "Bravo Band")

      assert %PagedEvents{
               events: [
                 {~D[2024-08-01],
                  [
                    %EventInfo{title: "Alpha Band"},
                    %EventInfo{title: "Bravo Band"},
                    %EventInfo{title: "Charlie Band"}
                  ]}
               ]
             } = Events.list_events()
    end

    test "sorts events by venue name when sort_by is :venue" do
      Repo.delete_all(Event)
      venue_z = insert(:venue, name: "Zebra Lounge")
      venue_a = insert(:venue, name: "Alpha Bar")
      venue_m = insert(:venue, name: "Mango Room")

      insert(:event, venue: venue_z, date: ~D[2024-08-01], title: "ev1")
      insert(:event, venue: venue_a, date: ~D[2024-08-01], title: "ev2")
      insert(:event, venue: venue_m, date: ~D[2024-08-01], title: "ev3")

      assert %PagedEvents{
               events: [
                 {~D[2024-08-01],
                  [
                    %EventInfo{title: "ev2", venue: %Venue{name: "Alpha Bar"}},
                    %EventInfo{title: "ev3", venue: %Venue{name: "Mango Room"}},
                    %EventInfo{title: "ev1", venue: %Venue{name: "Zebra Lounge"}}
                  ]}
               ]
             } = Events.list_events(sort_by: :venue)
    end
  end

  describe "list_events/1 with :search" do
    setup do
      venue = insert(:venue)

      # The factory defaults every event to headliner "Bob Mintzer", which now matters:
      # search reads the headliner too, so each fixture states its own bill explicitly.
      insert(:event,
        venue: venue,
        date: ~D[2024-08-01],
        title: "Bob Mintzer Quartet",
        headliner: "Bob Mintzer",
        openers: ["The Sidemen"]
      )

      insert(:event,
        venue: venue,
        date: ~D[2024-08-02],
        title: "bob mintzer big band",
        headliner: "bob mintzer"
      )

      insert(:event, venue: venue, date: ~D[2024-08-03], title: "Metric", headliner: "Metric")

      insert(:event,
        venue: venue,
        date: ~D[2024-08-04],
        title: "100% Silk Night",
        headliner: "Silk Night"
      )

      insert(:event,
        venue: venue,
        date: ~D[2024-08-05],
        title: "Drum_Circle",
        headliner: "Drum_Circle"
      )

      %{venue_id: venue.id}
    end

    defp titles(%PagedEvents{events: events}) do
      events
      |> Enum.flat_map(fn {_date, event_infos} -> event_infos end)
      |> Enum.map(& &1.title)
    end

    test "matches on a partial title, case insensitively" do
      assert ["Bob Mintzer Quartet", "bob mintzer big band"] =
               titles(Events.list_events(search: "MINTZER"))
    end

    test "requires every token to match, in any order" do
      assert ["Bob Mintzer Quartet"] = titles(Events.list_events(search: "quartet bob"))
    end

    test "returns no events when only some tokens match" do
      assert [] = titles(Events.list_events(search: "bob metric"))
    end

    test "ignores single character tokens" do
      assert ["Bob Mintzer Quartet", "bob mintzer big band"] =
               titles(Events.list_events(search: "mintzer x"))
    end

    test "treats % as a literal, not a wildcard" do
      assert ["100% Silk Night"] = titles(Events.list_events(search: "100%"))
    end

    test "treats _ as a literal, not a single character wildcard" do
      assert ["Drum_Circle"] = titles(Events.list_events(search: "drum_circle"))

      assert [] = titles(Events.list_events(search: "drumxcircle"))
    end

    test "nil and blank searches behave the same as no search at all" do
      unfiltered = titles(Events.list_events())

      assert unfiltered == titles(Events.list_events(search: nil))
      assert unfiltered == titles(Events.list_events(search: ""))
      assert unfiltered == titles(Events.list_events(search: "   "))
    end

    test "composes with the venue filter" do
      other_venue = insert(:venue)

      insert(:event,
        venue: other_venue,
        date: ~D[2024-08-06],
        title: "Bob Mintzer Trio",
        headliner: "Bob Mintzer"
      )

      assert ["Bob Mintzer Trio"] =
               titles(Events.list_events(search: "mintzer", venue_ids: [other_venue.id]))
    end

    test "composes with the from_date filter" do
      assert ["bob mintzer big band"] =
               titles(Events.list_events(search: "mintzer", from_date: ~D[2024-08-02]))
    end

    test "matches on the headliner when the title does not contain the term" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        date: ~D[2024-08-08],
        title: "Jazz Wednesdays",
        headliner: "Kalabash Trio"
      )

      assert ["Jazz Wednesdays"] = titles(Events.list_events(search: "kalabash"))
    end

    test "matches on an opener" do
      assert ["Bob Mintzer Quartet"] = titles(Events.list_events(search: "sidemen"))
    end

    test "matches when tokens are spread across the title, headliner and openers" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        date: ~D[2024-08-09],
        title: "Album Release Party",
        headliner: "Frigs",
        openers: ["Dilly Dally", "Weaves"]
      )

      assert ["Album Release Party"] = titles(Events.list_events(search: "frigs weaves release"))
    end

    test "does not match across two adjacent openers" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        date: ~D[2024-08-10],
        title: "Double Bill",
        headliner: "Headliner Band",
        openers: ["Alpha", "Beta"]
      )

      # "alphabeta" would only match if the openers array were joined without a separator.
      assert [] = titles(Events.list_events(search: "alphabeta"))
    end

    test "handles events with no openers" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        date: ~D[2024-08-11],
        title: "Solo Set",
        headliner: "Lido Pimienta",
        openers: []
      )

      assert ["Solo Set"] = titles(Events.list_events(search: "lido"))
    end

    test "still excludes deleted events" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        date: ~D[2024-08-07],
        title: "Bob Mintzer Deleted",
        headliner: "Bob Mintzer",
        deleted_at: DateHelpers.now()
      )

      refute "Bob Mintzer Deleted" in titles(Events.list_events(search: "mintzer"))
    end
  end

  describe "search_event_titles/2" do
    setup do
      venue = insert(:venue, name: "Suggestion Test Venue")

      insert(:event,
        venue: venue,
        date: ~D[2024-08-02],
        title: "Bob Mintzer Quartet",
        headliner: "Bob Mintzer",
        openers: ["The Sidemen"]
      )

      insert(:event,
        venue: venue,
        date: ~D[2024-08-03],
        title: "Bob Mintzer Quartet",
        headliner: "Bob Mintzer"
      )

      insert(:event,
        venue: venue,
        date: ~D[2024-08-04],
        title: "Bob Mintzer Big Band",
        headliner: "Bob Mintzer"
      )

      insert(:event,
        venue: venue,
        date: ~D[2024-07-01],
        title: "Bob Mintzer Past",
        headliner: "Bob Mintzer"
      )

      %{venue: venue}
    end

    test "carries the openers so a suggestion matched on a support act explains itself" do
      assert [%EventSuggestion{title: "Bob Mintzer Quartet", openers: ["The Sidemen"]}] =
               Events.search_event_titles("sidemen")
    end

    test "suggests events matched on the headliner alone", %{venue: venue} do
      insert(:event,
        venue: venue,
        date: ~D[2024-08-05],
        title: "Jazz Wednesdays",
        headliner: "Kalabash Trio"
      )

      assert [%EventSuggestion{title: "Jazz Wednesdays"}] =
               Events.search_event_titles("kalabash")
    end

    test "offers every date of a multi-night run, earliest first" do
      assert [
               %EventSuggestion{
                 title: "Bob Mintzer Quartet",
                 date: ~D[2024-08-02],
                 venue_name: "Suggestion Test Venue",
                 openers: ["The Sidemen"]
               },
               %EventSuggestion{title: "Bob Mintzer Quartet", date: ~D[2024-08-03]},
               %EventSuggestion{title: "Bob Mintzer Big Band", date: ~D[2024-08-04]}
             ] = Events.search_event_titles("mintzer")
    end

    test "caps a long residency so it cannot fill the dropdown", %{venue: venue} do
      for day <- 1..10 do
        insert(:event,
          venue: venue,
          date: Date.add(~D[2024-09-01], day),
          title: "Karaoke Thursdays",
          headliner: "Karaoke Thursdays"
        )
      end

      suggestions = Events.search_event_titles("karaoke")

      assert length(suggestions) == 3
      assert Enum.map(suggestions, & &1.date) == [~D[2024-09-02], ~D[2024-09-03], ~D[2024-09-04]]
    end

    test "counts the cap per venue, so a title running at two venues is not collapsed", %{
      venue: venue
    } do
      other_venue = insert(:venue, name: "Second Suggestion Venue")

      for {v, day} <- [{venue, 1}, {other_venue, 2}] do
        insert(:event,
          venue: v,
          date: Date.add(~D[2024-09-10], day),
          title: "Second Summer Festival",
          headliner: "Second Summer Festival"
        )
      end

      venue_names =
        "second summer"
        |> Events.search_event_titles()
        |> Enum.map(& &1.venue_name)

      assert venue_names == ["Suggestion Test Venue", "Second Suggestion Venue"]
    end

    test "excludes events in the past" do
      titles =
        "mintzer"
        |> Events.search_event_titles()
        |> Enum.map(& &1.title)

      refute "Bob Mintzer Past" in titles
    end

    test "respects the :limit option" do
      assert [%EventSuggestion{title: "Bob Mintzer Quartet"}] =
               Events.search_event_titles("mintzer", limit: 1)
    end

    test "returns an empty list for blank or unusable search terms" do
      assert [] = Events.search_event_titles(nil)
      assert [] = Events.search_event_titles("")
      assert [] = Events.search_event_titles("   ")
      assert [] = Events.search_event_titles("x")
    end

    test "returns an empty list when nothing matches" do
      assert [] = Events.search_event_titles("nonexistent band")
    end
  end

  describe "list_recently_added_events/1" do
    test "returns recently added upcoming events as EventInfo structs" do
      venue = insert(:venue)
      insert(:event, venue: venue, date: ~D[2024-08-10], title: "Recent Show")

      assert [%EventInfo{title: "Recent Show", venue: %Venue{}}] =
               Events.list_recently_added_events()
    end

    test "excludes events whose date has passed" do
      venue = insert(:venue)
      insert(:event, venue: venue, date: ~D[2024-07-15], title: "Past")
      insert(:event, venue: venue, date: ~D[2024-08-10], title: "Upcoming")

      titles = Events.list_recently_added_events() |> Enum.map(& &1.title)
      assert titles == ["Upcoming"]
    end

    test "excludes soft-deleted events" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        date: ~D[2024-08-10],
        title: "Deleted",
        deleted_at: DateTime.utc_now()
      )

      insert(:event, venue: venue, date: ~D[2024-08-10], title: "Live")

      titles = Events.list_recently_added_events() |> Enum.map(& &1.title)
      assert titles == ["Live"]
    end

    test "excludes events inserted before the lookback window" do
      venue = insert(:venue)
      old = insert(:event, venue: venue, date: ~D[2024-08-10], title: "Old")
      insert(:event, venue: venue, date: ~D[2024-08-10], title: "New")

      # The factory inserts at the mocked "now" (2024-08-01); push "Old" out of the window.
      from(e in Event, where: e.id == ^old.id)
      |> Repo.update_all(set: [inserted_at: ~U[2024-07-01 12:00:00Z]])

      titles = Events.list_recently_added_events(lookback_days: 14) |> Enum.map(& &1.title)
      assert titles == ["New"]
    end

    test "only includes events from venues opted into the recently added feed" do
      included_venue = insert(:venue, include_in_recently_added_feed?: true)
      excluded_venue = insert(:venue, include_in_recently_added_feed?: false)

      insert(:event, venue: included_venue, date: ~D[2024-08-10], title: "Included")
      insert(:event, venue: excluded_venue, date: ~D[2024-08-10], title: "Excluded")

      titles = Events.list_recently_added_events() |> Enum.map(& &1.title)
      assert titles == ["Included"]
    end

    test "caps a single venue so it cannot dominate the feed" do
      busy_venue = insert(:venue)
      other_venue = insert(:venue)

      for i <- 1..10 do
        insert(:event, venue: busy_venue, date: ~D[2024-08-10], title: "Busy #{i}")
      end

      insert(:event, venue: other_venue, date: ~D[2024-08-10], title: "Other")

      results = Events.list_recently_added_events(max_per_venue: 3)
      busy_count = Enum.count(results, &(&1.venue.id == busy_venue.id))
      other_count = Enum.count(results, &(&1.venue.id == other_venue.id))

      assert busy_count == 3
      assert other_count == 1
    end
  end

  describe "list_submitted_events/1" do
    setup do
      insert(:submitted_event, date: ~D[2024-07-30], title: "ev0")
      insert(:submitted_event, date: ~D[2024-08-01], title: "ev1")
      insert(:submitted_event, date: ~D[2024-08-01], title: "ev2")
      insert(:submitted_event, date: ~D[2024-08-02], title: "ev3")

      :ok
    end

    test "returns error when no user" do
      assert {:error, :not_allowed} == Events.list_submitted_events(nil)
    end

    test "returns error when user not an admin" do
      assert {:error, :not_allowed} == Events.list_submitted_events(%User{role: :regular_user})
    end

    test "lists events sorted by date and title" do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 %SubmittedEvent{
                   title: "ev0",
                   date: ~D[2024-07-30]
                 },
                 %SubmittedEvent{
                   title: "ev1",
                   date: ~D[2024-08-01]
                 },
                 %SubmittedEvent{
                   title: "ev2",
                   date: ~D[2024-08-01]
                 },
                 %SubmittedEvent{
                   title: "ev3",
                   date: ~D[2024-08-02]
                 }
               ]
             } = Events.list_submitted_events(%User{role: :admin})
    end

    test "excludes soft-deleted submitted events" do
      insert(:submitted_event, title: "deleted", deleted_at: DateHelpers.now())

      assert %PagedEvents{events: events} = Events.list_submitted_events(%User{role: :admin})

      refute Enum.any?(events, &(&1.title == "deleted"))
      assert length(events) == 4
    end
  end

  describe "delete_submitted_events/2" do
    setup do
      e0 = insert(:submitted_event, title: "ev0")
      e1 = insert(:submitted_event, title: "ev1")
      e2 = insert(:submitted_event, title: "ev2")
      %{e0: e0, e1: e1, e2: e2}
    end

    test "returns error when no user", %{e0: e0} do
      assert {:error, :not_allowed} == Events.delete_submitted_events(nil, [e0.id])
    end

    test "returns error when user not an admin", %{e0: e0} do
      assert {:error, :not_allowed} ==
               Events.delete_submitted_events(%User{role: :regular_user}, [e0.id])
    end

    test "soft-deletes the given submitted events", %{e0: e0, e1: e1, e2: e2} do
      assert {:ok, 2} = Events.delete_submitted_events(%User{role: :admin}, [e0.id, e1.id])

      assert Repo.get!(SubmittedEvent, e0.id).deleted_at == DateHelpers.now()
      assert Repo.get!(SubmittedEvent, e1.id).deleted_at == DateHelpers.now()
      assert Repo.get!(SubmittedEvent, e2.id).deleted_at == nil
    end
  end

  describe "update_submitted_event/3" do
    setup do
      submitted_event = insert(:submitted_event, venue: "Misspeld Venue")
      %{submitted_event: submitted_event}
    end

    test "admin can update fields", %{submitted_event: submitted_event} do
      assert {:ok, updated} =
               Events.update_submitted_event(
                 %User{role: :admin},
                 submitted_event.id,
                 %{venue: "Corrected Venue", time: "8:00 PM"}
               )

      assert updated.venue == "Corrected Venue"
      assert updated.time == "8:00 PM"

      reloaded = Repo.reload(submitted_event)
      assert reloaded.venue == "Corrected Venue"
      assert reloaded.time == "8:00 PM"
    end

    test "returns error when no user", %{submitted_event: submitted_event} do
      assert {:error, :not_allowed} ==
               Events.update_submitted_event(nil, submitted_event.id, %{venue: "Corrected Venue"})
    end

    test "returns error when user not an admin", %{submitted_event: submitted_event} do
      assert {:error, :not_allowed} ==
               Events.update_submitted_event(
                 %User{role: :regular_user},
                 submitted_event.id,
                 %{venue: "Corrected Venue"}
               )
    end

    test "returns error when submitted event not found" do
      assert {:error, :submitted_event_not_found} ==
               Events.update_submitted_event(%User{role: :admin}, -1, %{venue: "Corrected Venue"})
    end

    test "returns a changeset when a required field is blanked", %{
      submitted_event: submitted_event
    } do
      assert {:error, changeset} =
               Events.update_submitted_event(%User{role: :admin}, submitted_event.id, %{venue: ""})

      assert errors_on(changeset) == %{venue: ["can't be blank"]}
    end
  end

  describe "fetch_submitted_event/2" do
    setup do
      submitted_event = insert(:submitted_event)
      %{submitted_event: submitted_event}
    end

    test "admin fetches the submitted event", %{submitted_event: submitted_event} do
      assert {:ok, fetched} =
               Events.fetch_submitted_event(%User{role: :admin}, submitted_event.id)

      assert fetched.id == submitted_event.id
    end

    test "returns error when no user", %{submitted_event: submitted_event} do
      assert {:error, :not_allowed} ==
               Events.fetch_submitted_event(nil, submitted_event.id)
    end

    test "returns error when user not an admin", %{submitted_event: submitted_event} do
      assert {:error, :not_allowed} ==
               Events.fetch_submitted_event(%User{role: :regular_user}, submitted_event.id)
    end

    test "returns error when submitted event not found" do
      assert {:error, :submitted_event_not_found} ==
               Events.fetch_submitted_event(%User{role: :admin}, -1)
    end
  end

  describe "delete_event/2" do
    setup do
      venue = insert(:venue)
      event = insert(:event, venue: venue)
      %{event: event}
    end

    test "returns error when no user", %{event: event} do
      assert {:error, :not_allowed} == Events.delete_event(nil, event.id)
    end

    test "returns error when user not an admin", %{event: event} do
      assert {:error, :not_allowed} == Events.delete_event(%User{role: :regular_user}, event.id)
    end

    test "raises when event not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Events.delete_event(%User{role: :admin}, -1)
      end
    end

    test "deletes event", %{event: event} do
      assert {:ok, deleted_event} = Events.delete_event(%User{role: :admin}, event.id)

      assert event.id == deleted_event.id
      assert deleted_event.deleted_at == DateHelpers.now()
    end
  end

  describe "list_events_added_during_crawl/1" do
    # The crawl summary row is written when the crawl starts, so an event is
    # "added by" that crawl when it was inserted at or after that point. Note the
    # schema autogenerates timestamps from DateHelpers.now/0, which is frozen in
    # test - so anchor to it rather than the wall clock.
    defp crawl_summary(started_at) do
      %CrawlSummary{id: 1, inserted_at: started_at}
    end

    defp crawl_started_a_minute_ago do
      DateHelpers.now() |> DateTime.add(-60, :second) |> crawl_summary()
    end

    test "returns the events the crawl inserted" do
      venue = insert(:venue)
      insert(:event, venue: venue, title: "Brand New Show")

      assert [%Event{title: "Brand New Show"}] =
               Events.list_events_added_during_crawl(crawl_started_a_minute_ago())
    end

    test "excludes events that predate the crawl" do
      venue = insert(:venue)

      insert(:event,
        venue: venue,
        title: "Already Known Show",
        inserted_at: DateHelpers.now() |> DateTime.add(-1, :day)
      )

      assert [] == Events.list_events_added_during_crawl(crawl_started_a_minute_ago())
    end

    test "excludes deleted events" do
      venue = insert(:venue)
      insert(:event, venue: venue, title: "Cancelled Show", deleted_at: DateHelpers.now())

      assert [] == Events.list_events_added_during_crawl(crawl_started_a_minute_ago())
    end

    test "sorts by venue name, then date, then title" do
      zulu = insert(:venue, name: "Zulu Hall")
      alpha = insert(:venue, name: "Alpha Hall")

      insert(:event, venue: zulu, title: "Zulu Show", date: ~D[2024-08-02])
      insert(:event, venue: alpha, title: "Later Alpha Show", date: ~D[2024-08-03])
      insert(:event, venue: alpha, title: "Earlier Alpha Show", date: ~D[2024-08-02])
      # same venue and date as the above, so only the title can break the tie
      insert(:event, venue: alpha, title: "A Same Day Show", date: ~D[2024-08-02])

      assert [
               %Event{title: "A Same Day Show"},
               %Event{title: "Earlier Alpha Show"},
               %Event{title: "Later Alpha Show"},
               %Event{title: "Zulu Show"}
             ] = Events.list_events_added_during_crawl(crawl_started_a_minute_ago())
    end

    test "preloads the venue" do
      venue = insert(:venue, name: "Some Venue")
      insert(:event, venue: venue)

      assert [%Event{venue: %Venue{name: "Some Venue"}}] =
               Events.list_events_added_during_crawl(crawl_started_a_minute_ago())
    end

    test "returns an empty list when the crawl added nothing" do
      assert [] == Events.list_events_added_during_crawl(crawl_started_a_minute_ago())
    end
  end
end
