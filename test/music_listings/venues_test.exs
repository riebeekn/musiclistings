defmodule MusicListings.VenuesTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Venues
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.Venue

  describe "list_venues/0" do
    setup do
      Repo.delete_all(Venue)
      venue_2 = insert(:venue, name: "venue two", street: "v2 street")
      venue_1 = insert(:venue, name: "venue one", street: "v1 street")

      # mocked date of today is 2024-08-01
      _excluded_old_event =
        insert(:event, venue: venue_1, date: ~D[2024-07-30], title: "ev0")

      insert(:event, venue: venue_1, date: ~D[2024-08-01], title: "ev1")
      insert(:event, venue: venue_2, date: ~D[2024-08-01], title: "ev2")
      insert(:event, venue: venue_2, date: ~D[2024-08-02], title: "ev3")

      %{venue_1_id: venue_1.id, venue_2_id: venue_2.id}
    end

    test "returns the expected venue summary", %{venue_1_id: venue_1_id, venue_2_id: venue_2_id} do
      assert [
               %VenueSummary{
                 id: venue_1_id,
                 name: "venue one",
                 street: "v1 street",
                 upcoming_event_count: 1
               },
               %VenueSummary{
                 id: venue_2_id,
                 name: "venue two",
                 street: "v2 street",
                 upcoming_event_count: 2
               }
             ] ==
               Venues.list_venues()
    end
  end

  describe "fetch_venue_by_name/1" do
    setup do
      venue = insert(:venue, name: "Some Venue")

      %{venue_id: venue.id, venue: venue}
    end

    test "returns venue when it exists", %{venue_id: venue_id, venue: venue} do
      assert {:ok, %Venue{id: ^venue_id}} = Venues.fetch_venue_by_name(venue.name)
    end

    test "ignores casing", %{venue_id: venue_id, venue: venue} do
      upcase_name = String.upcase(venue.name)

      assert {:ok, %Venue{id: ^venue_id}} = Venues.fetch_venue_by_name(upcase_name)
    end

    test "returns error when not found" do
      assert {:error, :venue_not_found} = Venues.fetch_venue_by_name("non-existant venue")
    end
  end
end
