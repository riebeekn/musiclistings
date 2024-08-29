defmodule MusicListingsWeb.VenueLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicListings.EventsFixtures
  alias MusicListings.VenuesFixtures

  describe "index" do
    setup do
      venue_1 = VenuesFixtures.venue_fixture(name: "Venue 1", street: "1 Street")

      _excluded_old_event =
        EventsFixtures.event_fixture(venue_1, date: ~D[2024-07-30], title: "ev0")

      EventsFixtures.event_fixture(venue_1, date: ~D[2024-08-01], title: "ev1")
      EventsFixtures.event_fixture(venue_1, date: ~D[2024-08-01], title: "ev2")
      venue_2 = VenuesFixtures.venue_fixture(name: "Venue 2", street: "2 Street")
      EventsFixtures.event_fixture(venue_2, date: ~D[2024-08-02], title: "ev3")

      :ok
    end

    test "displays events for the specified venue", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/venues")

      assert html =~ "Venue 1"
      assert html =~ "1 Street"
      assert html =~ "2 Upcoming Events"

      assert html =~ "Venue 2"
      assert html =~ "2 Street"
      assert html =~ "1 Upcoming Events"
    end
  end
end
