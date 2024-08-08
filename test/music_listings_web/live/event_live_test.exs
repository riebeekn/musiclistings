defmodule MusicListingsWeb.EventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicListings.EventsFixtures
  alias MusicListings.VenuesFixtures

  describe "index" do
    setup do
      venue = VenuesFixtures.venue_fixture()
      e0 = EventsFixtures.event_fixture(venue, date: ~D[2024-07-30], title: "ev0")
      e1 = EventsFixtures.event_fixture(venue, date: ~D[2024-08-01], title: "ev1")
      e2 = EventsFixtures.event_fixture(venue, date: ~D[2024-08-01], title: "ev2")
      e3 = EventsFixtures.event_fixture(venue, date: ~D[2024-08-02], title: "ev3")

      %{e0_id: e0.id, e1_id: e1.id, e2_id: e2.id, e3_id: e3.id}
    end

    test "displays events", %{conn: conn, e0_id: e0_id, e1_id: e1_id, e2_id: e2_id, e3_id: e3_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      refute has_element?(view, "#event-#{e0_id}")
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")
    end
  end
end
