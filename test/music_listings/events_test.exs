defmodule MusicListings.EventsTest do
  use MusicListings.DataCase, async: true

  import Swoosh.TestAssertions

  alias MusicListings.Accounts.User
  alias MusicListings.Events
  alias MusicListings.Events.PagedEvents
  alias MusicListings.EventsFixtures
  alias MusicListings.VenuesFixtures
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsUtilities.DateHelpers

  describe "list_events/1" do
    setup do
      venue_1 = VenuesFixtures.venue_fixture()
      venue_2 = VenuesFixtures.venue_fixture()
      EventsFixtures.event_fixture(venue_1, date: ~D[2024-07-30], title: "ev0")
      EventsFixtures.event_fixture(venue_1, date: ~D[2024-08-01], title: "ev1")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-01], title: "ev2")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-02], title: "ev3")

      EventsFixtures.event_fixture(venue_2,
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
                    %Event{
                      title: "ev1",
                      date: ~D[2024-08-01],
                      venue_id: ^venue_1_id
                    },
                    %Event{
                      title: "ev2",
                      date: ~D[2024-08-01],
                      venue_id: ^venue_2_id
                    }
                  ]},
                 {~D[2024-08-02],
                  [
                    %Event{
                      title: "ev3",
                      date: ~D[2024-08-02],
                      venue_id: ^venue_2_id
                    }
                  ]}
               ]
             } = Events.list_events()
    end

    test "can filter by venue", %{venue_1_id: venue_1_id} do
      assert %MusicListings.Events.PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: [
                 {~D[2024-08-01],
                  [
                    %MusicListingsSchema.Event{
                      title: "ev1",
                      date: ~D[2024-08-01],
                      venue_id: ^venue_1_id
                    }
                  ]}
               ]
             } = Events.list_events(venue_ids: [venue_1_id])
    end
  end

  describe "submit_event/1" do
    test "with valid attributes creates a submitted event" do
      assert {:ok,
              %SubmittedEvent{
                title: "Event title",
                venue: "The Venue",
                date: ~D[2024-01-17],
                time: nil,
                price: nil,
                url: nil
              }} =
               Events.submit_event(%{
                 title: "Event title",
                 venue: "The Venue",
                 date: ~D[2024-01-17]
               })

      assert_email_sent(subject: "New Submitted Event")
    end

    test "returns a changeset with invalid attributes" do
      assert {:error, changeset} = Events.submit_event(%{})

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               title: ["can't be blank"],
               venue: ["can't be blank"]
             }

      refute_email_sent()
    end
  end

  describe "delete_event/2" do
    setup do
      venue = VenuesFixtures.venue_fixture()
      event = EventsFixtures.event_fixture(venue)
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
