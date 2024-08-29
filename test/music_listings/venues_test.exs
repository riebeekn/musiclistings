defmodule MusicListings.VenuesTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.EventsFixtures
  alias MusicListings.Venues
  alias MusicListings.Venues.VenueSummary
  alias MusicListings.VenuesFixtures

  describe "list_venues/0" do
    setup do
      venue_1 = VenuesFixtures.venue_fixture(name: "venue two", street: "v2 street")
      venue_2 = VenuesFixtures.venue_fixture(name: "venue one", street: "v1 street")

      # mocked date of today is 2024-08-01
      _excluded_old_event =
        EventsFixtures.event_fixture(venue_1, date: ~D[2024-07-30], title: "ev0")

      EventsFixtures.event_fixture(venue_1, date: ~D[2024-08-01], title: "ev1")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-01], title: "ev2")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-02], title: "ev3")

      %{venue_1_id: venue_1.id, venue_2_id: venue_2.id}
    end

    test "returns the expected venue summary" do
      assert [
               %VenueSummary{
                 name: "venue one",
                 street: "v1 street",
                 upcoming_event_count: 2
               },
               %VenueSummary{
                 name: "venue two",
                 street: "v2 street",
                 upcoming_event_count: 1
               }
             ] ==
               Venues.list_venues()
    end
  end
end
