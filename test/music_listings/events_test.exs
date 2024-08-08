defmodule MusicListings.EventsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Events
  alias MusicListings.Events.PagedEvents
  alias MusicListings.EventsFixtures
  alias MusicListings.VenuesFixtures
  alias MusicListingsSchema.Event

  describe "list_events/1" do
    setup do
      venue_1 = VenuesFixtures.venue_fixture()
      venue_2 = VenuesFixtures.venue_fixture()
      EventsFixtures.event_fixture(venue_1, date: ~D[2024-07-30], title: "ev0")
      EventsFixtures.event_fixture(venue_1, date: ~D[2024-08-01], title: "ev1")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-01], title: "ev2")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-02], title: "ev3")

      %{venue_1_id: venue_1.id, venue_2_id: venue_2.id}
    end

    test "lists events grouped by date, ignoring events in the past", %{
      venue_1_id: venue_1_id,
      venue_2_id: venue_2_id
    } do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: %{
                 ~D[2024-08-01] => [
                   %Event{
                     venue_id: ^venue_1_id,
                     title: "ev1",
                     date: ~D[2024-08-01]
                   },
                   %Event{
                     venue_id: ^venue_2_id,
                     title: "ev2",
                     date: ~D[2024-08-01]
                   }
                 ],
                 ~D[2024-08-02] => [
                   %Event{
                     venue_id: ^venue_2_id,
                     title: "ev3",
                     date: ~D[2024-08-02]
                   }
                 ]
               }
             } = Events.list_events()
    end

    test "can filter by venue", %{venue_1_id: venue_1_id} do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: %{
                 ~D[2024-08-01] => [
                   %Event{
                     venue_id: ^venue_1_id,
                     title: "ev1",
                     date: ~D[2024-08-01]
                   }
                 ]
               }
             } = Events.list_events(venue_id: venue_1_id)
    end
  end
end
