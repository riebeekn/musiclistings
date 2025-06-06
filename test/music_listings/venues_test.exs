defmodule MusicListings.VenuesTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Accounts.User
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

  describe "create_venue/2" do
    test "returns error when no user" do
      assert {:error, :not_allowed} == Venues.create_venue(nil, %{})
    end

    test "returns error when user not an admin" do
      assert {:error, :not_allowed} == Venues.create_venue(%User{role: :regular_user}, %{})
    end

    @valid_attrs %{
      name: "Bob's Bar",
      street: "123 Street",
      city: "TO",
      province: "ON",
      country: "CA",
      postal_code: "PC",
      website: "WS",
      google_map_url: "MURL",
      parser_module_name: "n/a",
      pull_events?: false
    }
    test "with valid attributes creates a venue" do
      assert {:ok, @valid_attrs} = Venues.create_venue(%User{role: :admin}, @valid_attrs)
    end

    test "returns a changeset with invalid attributes" do
      assert {:error, changeset} = Venues.create_venue(%User{role: :admin}, %{})

      assert errors_on(changeset) == %{
               city: ["can't be blank"],
               country: ["can't be blank"],
               google_map_url: ["can't be blank"],
               name: ["can't be blank"],
               parser_module_name: ["can't be blank"],
               postal_code: ["can't be blank"],
               province: ["can't be blank"],
               pull_events?: ["can't be blank"],
               street: ["can't be blank"],
               website: ["can't be blank"]
             }
    end
  end
end
