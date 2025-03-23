defmodule MusicListingsWeb.VenueEventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "index" do
    setup do
      venue = insert(:venue)
      e0 = insert(:event, venue: venue, date: ~D[2024-07-30], title: "ev0")
      e1 = insert(:event, venue: venue, date: ~D[2024-08-01], title: "ev1")
      e2 = insert(:event, venue: venue, date: ~D[2024-08-01], title: "ev2")
      venue_2 = insert(:venue)
      e3 = insert(:event, venue: venue_2, date: ~D[2024-08-02], title: "ev3")

      %{venue_id: venue.id, e0_id: e0.id, e1_id: e1.id, e2_id: e2.id, e3_id: e3.id}
    end

    test "displays events for the specified venue", %{
      conn: conn,
      venue_id: venue_id,
      e0_id: e0_id,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events/venue/#{venue_id}")

      refute has_element?(view, "#event-#{e0_id}")
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      refute has_element?(view, "#event-#{e3_id}")
    end

    test "does not show the delete buttons", %{
      conn: conn,
      venue_id: venue_id,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events/venue/#{venue_id}")

      refute has_element?(view, "#event-#{e1_id} button")
      refute has_element?(view, "#event-#{e2_id} button")
    end
  end

  describe "index - logged in as admin" do
    setup :register_and_log_in_user

    setup do
      venue = insert(:venue)
      event = insert(:event, venue: venue, date: ~D[2024-08-01])

      %{venue_id: venue.id, event_id: event.id}
    end

    test "can delete an event", %{conn: conn, venue_id: venue_id, event_id: event_id} do
      {:ok, view, _html} = live(conn, ~p"/events/venue/#{venue_id}")

      view
      |> element("#event-#{event_id} button")
      |> render_click()

      refute has_element?(view, "#event-#{event_id}")
    end
  end
end
