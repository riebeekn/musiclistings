defmodule MusicListings.VenuesTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Accounts.User
  alias MusicListings.Venues
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.Event
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

    test "with only_with_upcoming_events?: true excludes venues without upcoming events" do
      Repo.delete_all(Event)
      Repo.delete_all(Venue)
      venue_with_upcoming = insert(:venue, name: "has upcoming", street: "a street")
      venue_with_only_past = insert(:venue, name: "only past", street: "b street")
      _venue_with_no_events = insert(:venue, name: "no events", street: "c street")

      # mocked date of today is 2024-08-01
      insert(:event, venue: venue_with_upcoming, date: ~D[2024-08-01], title: "ev1")
      insert(:event, venue: venue_with_only_past, date: ~D[2024-07-30], title: "ev0")

      venue_with_upcoming_id = venue_with_upcoming.id

      assert [
               %VenueSummary{
                 id: ^venue_with_upcoming_id,
                 name: "has upcoming",
                 upcoming_event_count: 1
               }
             ] = Venues.list_venues(only_with_upcoming_events?: true)
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

  describe "fetch_venue_by_parser_module_name/1" do
    setup do
      venue = insert(:venue, parser_module_name: "SomeVenueParser")

      %{venue_id: venue.id}
    end

    test "returns venue when it exists", %{venue_id: venue_id} do
      assert {:ok, %Venue{id: ^venue_id}} =
               Venues.fetch_venue_by_parser_module_name("SomeVenueParser")
    end

    test "ignores casing", %{venue_id: venue_id} do
      assert {:ok, %Venue{id: ^venue_id}} =
               Venues.fetch_venue_by_parser_module_name("somevenueparser")
    end

    test "returns error when not found" do
      assert {:error, :venue_not_found} =
               Venues.fetch_venue_by_parser_module_name("NonExistantParser")
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

  describe "list_venues/1 with restrict_to_pulled_venues?: false" do
    test "includes venues not being crawled, flagged as such" do
      Repo.delete_all(Event)
      Repo.delete_all(Venue)
      insert(:venue, name: "pulled", pull_events?: true)
      insert(:venue, name: "not pulled", pull_events?: false)

      assert [%VenueSummary{name: "pulled"}] = Venues.list_venues()

      assert [
               %VenueSummary{name: "not pulled", pull_events?: false},
               %VenueSummary{name: "pulled", pull_events?: true}
             ] = Venues.list_venues(restrict_to_pulled_venues?: false)
    end
  end

  describe "set_pull_events/3" do
    setup do
      %{venue: insert(:venue, pull_events?: true)}
    end

    test "turns crawling a venue off and on", %{venue: venue} do
      assert {:ok, %Venue{pull_events?: false}} =
               Venues.set_pull_events(%User{role: :admin}, venue.id, false)

      assert {:ok, %Venue{pull_events?: true}} =
               Venues.set_pull_events(%User{role: :admin}, to_string(venue.id), true)

      assert Repo.get!(Venue, venue.id).pull_events?
    end

    test "returns error when no user", %{venue: venue} do
      assert {:error, :not_allowed} == Venues.set_pull_events(nil, venue.id, false)
      assert Repo.get!(Venue, venue.id).pull_events?
    end

    test "returns error when user not an admin", %{venue: venue} do
      assert {:error, :not_allowed} ==
               Venues.set_pull_events(%User{role: :regular_user}, venue.id, false)

      assert Repo.get!(Venue, venue.id).pull_events?
    end

    test "returns error when the venue doesn't exist" do
      assert {:error, :venue_not_found} == Venues.set_pull_events(%User{role: :admin}, -1, false)
    end
  end
end
