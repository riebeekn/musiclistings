defmodule MusicListings.EventsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Events
  alias MusicListings.Events.PagedEvents
  alias MusicListings.VenuesFixtures
  alias MusicListingsSchema.Event

  alias MusicListings.EventsFixtures

  describe "list_events/1" do
    setup do
      venue = VenuesFixtures.venue_fixture()
      EventsFixtures.event_fixture(venue, date: ~D[2024-07-30], title: "ev0")
      EventsFixtures.event_fixture(venue, date: ~D[2024-08-01], title: "ev1")
      EventsFixtures.event_fixture(venue, date: ~D[2024-08-01], title: "ev2")
      EventsFixtures.event_fixture(venue, date: ~D[2024-08-02], title: "ev3")

      :ok
    end

    test "lists events grouped by date, ignoring events in the past" do
      assert %PagedEvents{
               current_page: 1,
               total_pages: 1,
               events: %{
                 ~D[2024-08-01] => [
                   %Event{
                     title: "ev1",
                     date: ~D[2024-08-01]
                   },
                   %Event{
                     title: "ev2",
                     date: ~D[2024-08-01]
                   }
                 ],
                 ~D[2024-08-02] => [
                   %Event{
                     title: "ev3",
                     date: ~D[2024-08-02]
                   }
                 ]
               }
             } = Events.list_events()
    end
  end
end
