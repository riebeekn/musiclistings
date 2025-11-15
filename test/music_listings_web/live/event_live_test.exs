defmodule MusicListingsWeb.EventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "index" do
    setup do
      today = Date.utc_today()
      yesterday = Date.add(today, -1)
      tomorrow = Date.add(today, 1)

      e0 = insert(:event, date: yesterday, title: "ev0")
      e1 = insert(:event, date: today, title: "ev1")
      e2 = insert(:event, date: today, title: "ev2")
      e3 = insert(:event, date: tomorrow, title: "ev3")

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
      today = Date.utc_today()
      venue = insert(:venue)
      e1 = insert(:event, venue: venue, date: today, title: "ev1")
      e2 = insert(:event, venue: venue, date: Date.add(today, 4), title: "ev2")
      e3 = insert(:event, venue: venue, date: Date.add(today, 9), title: "ev3")

      %{venue_id: venue.id, e1_id: e1.id, e2_id: e2.id, e3_id: e3.id, today: today}
    end

    test "filters events by selected date", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id,
      today: today
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      # Initially all events should be visible (default filter is today)
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Filter to show events from 4 days from now onwards
      filter_date = Date.add(today, 4)

      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => Date.to_iso8601(filter_date)})

      # Only e2 and e3 should be visible
      refute has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Should show the date filter status message (since it's not today)
      assert render(view) =~ "Showing events from"
    end

    test "clears date filter", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id,
      today: today
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      # Apply a date filter
      filter_date = Date.add(today, 9)

      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => Date.to_iso8601(filter_date)})

      # Only e3 should be visible
      refute has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Clear the filter (should reset to today)
      view
      |> element("#clear-date-filter")
      |> render_click()

      # All events should be visible again (starting from today)
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Filter status message should be gone (since filter is today)
      refute render(view) =~ "Showing events from"
    end

    test "combines date filter with venue filter (venue filter first)", %{
      conn: conn,
      venue_id: venue_id,
      today: today
    } do
      # Create another venue with events
      other_venue = insert(:venue)
      e4 = insert(:event, venue: other_venue, date: Date.add(today, 4), title: "ev4")

      {:ok, view, _html} = live(conn, ~p"/events")

      # Apply venue filter first
      view
      |> element("#venue-filters")
      |> render_change(%{"#{venue_id}" => "true"})

      # Should show events from first venue only
      refute has_element?(view, "#event-#{e4.id}")

      # Now apply date filter
      filter_date = Date.add(today, 4)

      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => Date.to_iso8601(filter_date)})

      # Should show only events from first venue starting from the filter date
      refute has_element?(view, "#event-#{e4.id}")
    end

    test "combines date filter with venue filter (date filter first)", %{
      conn: conn,
      venue_id: venue_id,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id,
      today: today
    } do
      # Create another venue with events
      other_venue = insert(:venue)
      e4 = insert(:event, venue: other_venue, date: Date.add(today, 4), title: "ev4")

      {:ok, view, _html} = live(conn, ~p"/events")

      # Apply date filter first
      filter_date = Date.add(today, 4)

      view
      |> element("#date-filter-form")
      |> render_change(%{"date" => Date.to_iso8601(filter_date)})

      # Should show e2, e3, and e4 (all events from filter_date onwards)
      refute has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")
      assert has_element?(view, "#event-#{e4.id}")

      # Now apply venue filter (this is where the bug occurred)
      view
      |> element("#venue-filters")
      |> render_change(%{"#{venue_id}" => "true"})

      # Should show only events from first venue starting from the filter date
      refute has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")
      refute has_element?(view, "#event-#{e4.id}")
    end
  end

  describe "index - logged in as admin" do
    setup :register_and_log_in_user

    setup do
      today = Date.utc_today()
      event = insert(:event, date: today)
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
