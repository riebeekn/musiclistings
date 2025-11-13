defmodule MusicListingsWeb.EventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "index" do
    setup do
      e0 = insert(:event, date: ~D[2024-07-30], title: "ev0")
      e1 = insert(:event, date: ~D[2024-08-01], title: "ev1")
      e2 = insert(:event, date: ~D[2024-08-01], title: "ev2")
      e3 = insert(:event, date: ~D[2024-08-02], title: "ev3")

      %{e0_id: e0.id, e1_id: e1.id, e2_id: e2.id, e3_id: e3.id}
    end

    test "displays events", %{conn: conn, e0_id: e0_id, e1_id: e1_id, e2_id: e2_id, e3_id: e3_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      refute has_element?(view, "#event-#{e0_id}")
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")
    end

    test "does not show the delete buttons", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      refute has_element?(view, "#event-#{e1_id} button")
      refute has_element?(view, "#event-#{e2_id} button")
      refute has_element?(view, "#event-#{e3_id} button")
    end
  end

  describe "date filtering" do
    setup do
      venue = insert(:venue)
      e1 = insert(:event, venue: venue, date: ~D[2024-08-01], title: "ev1")
      e2 = insert(:event, venue: venue, date: ~D[2024-08-05], title: "ev2")
      e3 = insert(:event, venue: venue, date: ~D[2024-08-10], title: "ev3")

      %{venue_id: venue.id, e1_id: e1.id, e2_id: e2.id, e3_id: e3.id}
    end

    test "filters events by selected date", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      # Initially all events should be visible
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Filter to show events from 2024-08-05 onwards
      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => "2024-08-05"})

      # Only e2 and e3 should be visible
      refute has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Should show the date filter status message
      assert render(view) =~ "Showing events from"
      assert render(view) =~ "Mon, Aug 05 2024"
    end

    test "clears date filter", %{conn: conn, e1_id: e1_id, e2_id: e2_id, e3_id: e3_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      # Apply a date filter
      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => "2024-08-10"})

      # Only e3 should be visible
      refute has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Clear the filter
      view
      |> element("#clear-date-filter")
      |> render_click()

      # All events should be visible again
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Filter status message should be gone
      refute render(view) =~ "Showing events from"
    end

    test "combines date filter with venue filter", %{conn: conn, venue_id: venue_id} do
      # Create another venue with events
      other_venue = insert(:venue)
      e4 = insert(:event, venue: other_venue, date: ~D[2024-08-05], title: "ev4")

      {:ok, view, _html} = live(conn, ~p"/events")

      # Apply venue filter first
      view
      |> element("#venue-filters")
      |> render_change(%{"#{venue_id}" => "true"})

      # Should show events from first venue only
      refute has_element?(view, "#event-#{e4.id}")

      # Now apply date filter
      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => "2024-08-05"})

      # Should show only events from first venue starting from Aug 5
      refute has_element?(view, "#event-#{e4.id}")
    end
  end

  describe "index - logged in as admin" do
    setup :register_and_log_in_user

    setup do
      event = insert(:event, date: ~D[2024-08-01])
      %{event_id: event.id}
    end

    test "can delete an event", %{conn: conn, event_id: event_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#event-#{event_id} button")
      |> render_click()

      refute has_element?(view, "#event-#{event_id}")
    end
  end

  describe "new" do
    test "saves submitted event with valid parameters", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events/new")
      assert has_element?(view, "h1", "Submit Your Event")

      {:ok, _view, html} =
        view
        |> form("#event-form", %{
          "event" => %{
            "title" => "the title for the event",
            "venue" => "some venue",
            "date" => ~D[2024-01-17]
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/events")

      assert html =~ "Thank you for submitting your event!"
    end

    test "displays errors with invalid attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events/new")

      view
      |> form("#event-form", %{"event" => %{}})

      assert view
             |> form("#event-form", %{"event" => %{}})
             |> render_submit() =~ "can&#39;t be blank"
    end
  end
end
