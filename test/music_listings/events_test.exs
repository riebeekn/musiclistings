defmodule MusicListings.EventsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Accounts.User
  alias MusicListings.Events
  alias MusicListings.Events.EventInfo
  alias MusicListings.Events.PagedEvents
  alias MusicListings.Events.ShowTimeInfo
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
end
