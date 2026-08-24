defmodule MusicListingsWeb.EventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicListingsUtilities.DateHelpers

  describe "index" do
    setup do
      today = DateHelpers.today_eastern()
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
      today = DateHelpers.today_eastern()
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
      |> render_submit(%{"date" => Date.to_iso8601(filter_date)})

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
      |> render_submit(%{"date" => Date.to_iso8601(filter_date)})

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
      |> render_submit(%{"date" => Date.to_iso8601(filter_date)})

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
      |> render_submit(%{"date" => Date.to_iso8601(filter_date)})

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

    test "resets past dates in localStorage to today on mount", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id,
      today: today
    } do
      # Simulate localStorage containing a past date
      past_date = Date.add(today, -5)

      {:ok, view, _html} =
        conn
        |> put_connect_params(%{"selected_date" => Date.to_iso8601(past_date)})
        |> live(~p"/events")

      # All events from today onwards should be visible (not from the past date)
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-#{e3_id}")

      # Filter status message should not be shown (since we reset to today)
      refute render(view) =~ "Showing events from"
    end
  end

  describe "search" do
    setup do
      today = DateHelpers.today_eastern()
      venue = insert(:venue)

      # Search reads the headliner and openers as well as the title, so the fixtures spell
      # out their own bills rather than inheriting the factory's default headliner.
      e1 =
        insert(:event,
          venue: venue,
          date: today,
          title: "Bob Mintzer Quartet",
          headliner: "Bob Mintzer"
        )

      e2 =
        insert(:event,
          venue: venue,
          date: Date.add(today, 1),
          title: "Metric",
          headliner: "Metric"
        )

      e3 =
        insert(:event,
          venue: venue,
          date: Date.add(today, 2),
          title: "Bob Mintzer Big Band",
          headliner: "Bob Mintzer"
        )

      e4 =
        insert(:event,
          venue: venue,
          date: Date.add(today, 3),
          title: "Album Release Party",
          headliner: "Frigs",
          openers: ["Dilly Dally"]
        )

      %{venue_id: venue.id, e1_id: e1.id, e2_id: e2.id, e3_id: e3.id, e4_id: e4.id}
    end

    defp search(view, term) do
      view
      |> element("#search-form")
      |> render_change(%{"q" => term})
    end

    test "scopes the listing to matching titles", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id,
      e3_id: e3_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{e2_id}")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "mintzer"})

      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e3_id}")
      refute has_element?(view, "#event-#{e2_id}")
    end

    test "scopes the listing on a headliner that is not in the title", %{
      conn: conn,
      e1_id: e1_id,
      e4_id: e4_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "frigs"})

      assert has_element?(view, "#event-#{e4_id}")
      refute has_element?(view, "#event-#{e1_id}")
    end

    test "scopes the listing on an opener", %{conn: conn, e1_id: e1_id, e4_id: e4_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "dilly dally"})

      assert has_element?(view, "#event-#{e4_id}")
      refute has_element?(view, "#event-#{e1_id}")
    end

    test "names the openers on a suggestion matched by its support act", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")

      html =
        view
        |> element("#search-form")
        |> render_change(%{"q" => "dilly"})

      assert html =~ "Album Release Party"
      assert html =~ "with Dilly Dally"
    end

    test "submitting closes the dropdown but keeps the term and the scoped listing", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "mintzer"})

      assert has_element?(view, "#search-suggestions")

      html =
        view
        |> element("#search-form")
        |> render_submit(%{"q" => "mintzer"})

      refute has_element?(view, "#search-suggestions")
      assert html =~ ~s(value="mintzer")
      assert has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
      refute_patched(view)
    end

    test "submitting a term typed inside the debounce window still scopes the listing", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      # No preceding render_change: this is the "typed fast and hit Enter" path, where the
      # debounced change event never fired and submit carries the only copy of the term.
      view
      |> element("#search-form")
      |> render_submit(%{"q" => "mintzer"})

      assert has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
    end

    test "submitting an empty box clears the search", %{conn: conn, e2_id: e2_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      search(view, "mintzer")
      refute has_element?(view, "#event-#{e2_id}")

      view
      |> element("#search-form")
      |> render_submit(%{"q" => ""})

      assert has_element?(view, "#event-#{e2_id}")
    end

    # Search is deliberately the one filter with no URL presence: it should not survive a
    # refresh or a back-navigation the way the localStorage-backed filters do.
    test "searching never touches the URL", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")

      search(view, "mintzer")

      refute_patched(view)
    end

    test "a fresh load is unscoped, even with a stale q param in the URL", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events?#{[q: "mintzer"]}")

      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-search[value='']")
    end

    test "reloading after a search returns the full listing", %{conn: conn, e2_id: e2_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      search(view, "mintzer")
      refute has_element?(view, "#event-#{e2_id}")

      {:ok, reloaded, _html} = live(conn, ~p"/events")

      assert has_element?(reloaded, "#event-#{e2_id}")
      assert has_element?(reloaded, "#event-search[value='']")
    end

    test "shows typeahead suggestions linking straight to the event", %{
      conn: conn,
      e1_id: e1_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      refute has_element?(view, "#search-suggestions")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "mintzer"})

      assert has_element?(view, "#search-suggestions [data-suggestion]", "Bob Mintzer Quartet")
      assert has_element?(view, "#search-suggestions [data-suggestion]", "Bob Mintzer Big Band")

      assert has_element?(
               view,
               "#search-suggestions a[href='/events/#{e1_id}/bob-mintzer-quartet']"
             )
    end

    test "does not offer suggestions for a single character term", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "m"})

      refute has_element?(view, "#search-suggestions")
    end

    test "dismisses the suggestions without clearing the search", %{conn: conn, e1_id: e1_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#search-form")
      |> render_change(%{"q" => "mintzer"})

      assert has_element?(view, "#search-suggestions")

      render_click(view, "dismiss-suggestions", %{})

      refute has_element?(view, "#search-suggestions")
      # the listing stays scoped
      assert has_element?(view, "#event-#{e1_id}")
    end

    test "clearing the search restores the full listing", %{
      conn: conn,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      search(view, "mintzer")
      refute has_element?(view, "#event-#{e2_id}")

      view
      |> element("#search-bar-component button[phx-click='clear-search']")
      |> render_click()

      assert has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-search[value='']")
    end

    test "shows an empty state naming the term when nothing matches", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")

      html = search(view, "nonexistent band")

      assert html =~ "No upcoming events match"
      assert html =~ "nonexistent band"
    end

    test "renders one search bar serving both breakpoints", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")
      search(view, "mintzer")

      # A single field, not the desktop/mobile pair the other filters use.
      assert [_only_one] = view |> render() |> then(&Regex.scan(~r/id="event-search"/, &1))
      assert has_element?(view, "#event-search[value='mintzer']")
      assert has_element?(view, "button[phx-click='clear-search'][aria-label='Clear search']")
    end

    # The pager patches rather than navigates, so the term rides along in assigns.  This is
    # the invariant that replaced carrying "q" in the pager's query string: if handle_params
    # ever resets search_term again, page 2 of a search silently becomes the full listing.
    test "the search survives paging", %{conn: conn, e1_id: e1_id, e2_id: e2_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      search(view, "mintzer")

      render_patch(view, ~p"/events?page=1")

      assert has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
      assert has_element?(view, "#event-search[value='mintzer']")
    end

    test "the search survives changing the sort order", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")
      search(view, "mintzer")

      view
      |> element("#sort-by-component button[phx-value-sort-by='venue']")
      |> render_click()

      assert has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
    end

    test "the search survives clearing the venue filter", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")
      search(view, "mintzer")

      render_click(view, "clear-venue-filtering", %{})

      assert has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
    end

    test "handles an empty or whitespace-only term without crashing", %{
      conn: conn,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      for query <- ["", "  ", "\t"] do
        html = search(view, query)

        assert has_element?(view, "#event-#{e2_id}")
        refute html =~ "No upcoming events match"
      end
    end

    test "truncates a term that exceeds the length cap", %{conn: conn, e1_id: e1_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      # The input carries a matching maxlength, but a crafted payload can ignore it, so the
      # server has to be the thing that bounds the LIKE pattern.
      html = search(view, "mintzer" <> String.duplicate("a", 200))

      refute has_element?(view, "#event-#{e1_id}")

      assert [term] =
               Regex.run(~r/id="event-search"[^>]*value="([^"]*)"/, html, capture: :all_but_first)

      assert String.length(term) == 100
    end

    test "treats wildcard characters as literals rather than matching everything", %{
      conn: conn,
      e1_id: e1_id,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      # "mint%" would match "Bob Mintzer Quartet" if % were passed through to LIKE.
      html = search(view, "mint%")

      refute has_element?(view, "#event-#{e1_id}")
      refute has_element?(view, "#event-#{e2_id}")
      assert html =~ "No upcoming events match"
    end
  end

  describe "sorting" do
    setup do
      today = DateHelpers.today_eastern()
      venue_a = insert(:venue, name: "Alpha Venue")
      venue_z = insert(:venue, name: "Zebra Venue")

      e1 = insert(:event, venue: venue_z, date: today, title: "Zebra Show")
      e2 = insert(:event, venue: venue_a, date: today, title: "Alpha Show")

      %{venue_a: venue_a, venue_z: venue_z, e1_id: e1.id, e2_id: e2.id}
    end

    test "sort toggle defaults to title", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")

      # The title button should have the active styling
      assert has_element?(view, "button", "By Title")
      assert has_element?(view, "button", "By Venue")
    end

    test "sort toggle changes event ordering", %{conn: conn, e1_id: e1_id, e2_id: e2_id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      # Both events should be visible
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")

      # Change sort to venue
      view
      |> element("#sort-by-component button", "By Venue")
      |> render_click()

      # Both events should still be visible after sort change
      assert has_element?(view, "#event-#{e1_id}")
      assert has_element?(view, "#event-#{e2_id}")
    end

    test "restores sort_by from localStorage", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> put_connect_params(%{"sort_by" => "venue"})
        |> live(~p"/events")

      # Should render without error with venue sort restored
      assert has_element?(view, "#sort-by-component")
    end

    test "invalid sort_by in localStorage defaults to title", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> put_connect_params(%{"sort_by" => "invalid_value"})
        |> live(~p"/events")

      # Should render without error, defaulting to title sort
      assert has_element?(view, "#sort-by-component")
    end

    test "sort persists through venue filter changes", %{
      conn: conn,
      venue_a: venue_a,
      e2_id: e2_id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      # Change sort to venue
      view
      |> element("#sort-by-component button", "By Venue")
      |> render_click()

      # Apply venue filter
      view
      |> element("#venue-filters")
      |> render_change(%{"#{venue_a.id}" => "true"})

      # Event from filtered venue should still be visible
      assert has_element?(view, "#event-#{e2_id}")
    end
  end

  describe "index - logged in as admin" do
    setup :register_and_log_in_user

    setup do
      today = DateHelpers.today_eastern()
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

  describe "newly added rail (feature flag)" do
    setup do
      today = DateHelpers.today_eastern()
      event = insert(:event, date: today, title: "Freshly Added Show")
      %{event_id: event.id}
    end

    test "rail is hidden by default (flag off)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events")

      refute render(view) =~ "New This Week"
    end

    test "rail is shown when the flag is enabled", %{conn: conn} do
      FunWithFlags.enable(:show_recently_added)

      {:ok, view, _html} = live(conn, ~p"/events")

      assert render(view) =~ "New This Week"
    end
  end

  describe "resale links (feature flag)" do
    @resale_url "https://goto.ticketnetwork.com/c/1001"

    setup do
      today = DateHelpers.today_eastern()
      venue = insert(:venue)

      with_resale =
        insert(:event,
          venue: venue,
          date: today,
          title: "ev-resale",
          ticketnetwork_url: @resale_url
        )

      without_resale =
        insert(:event, venue: venue, date: today, title: "ev-plain", ticketnetwork_url: nil)

      %{with_resale_id: with_resale.id, without_resale_id: without_resale.id}
    end

    test "resale link is hidden by default (flag off)", %{conn: conn, with_resale_id: id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{id}")
      refute has_element?(view, "#event-#{id} a[href='#{@resale_url}']")
    end

    test "resale link is shown when the flag is enabled", %{conn: conn, with_resale_id: id} do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{id} a[href='#{@resale_url}']")
    end

    test "renders nothing for events without a ticketnetwork url", %{
      conn: conn,
      without_resale_id: id
    } do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{id}")
      refute has_element?(view, "#event-#{id} a[rel='noopener sponsored'][href^='https://goto']")
    end

    test "primary ticket link is rendered before the resale link", %{
      conn: conn,
      with_resale_id: id
    } do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, view, _html} = live(conn, ~p"/events")

      row = view |> element("#event-#{id}") |> render()

      assert :binary.match(row, "https://tickets@example.com") <
               :binary.match(row, @resale_url)
    end

    test "resale link is shown when sorting by venue", %{conn: conn, with_resale_id: id} do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, view, _html} =
        conn |> put_connect_params(%{"sort_by" => "venue"}) |> live(~p"/events")

      assert has_element?(view, "#event-#{id} a[href='#{@resale_url}']")
    end
  end

  describe "duplicate info / ticket links" do
    @shared_url "https://example.com/events/shared"
    @distinct_details_url "https://example.com/events/details"

    setup do
      today = DateHelpers.today_eastern()
      venue = insert(:venue)

      duplicate =
        insert(:event,
          venue: venue,
          date: today,
          title: "ev-duplicate",
          ticket_url: @shared_url,
          details_url: @shared_url
        )

      distinct =
        insert(:event,
          venue: venue,
          date: today,
          title: "ev-distinct",
          ticket_url: @shared_url,
          details_url: @distinct_details_url
        )

      ticketless =
        insert(:event,
          venue: venue,
          date: today,
          title: "ev-ticketless",
          ticket_url: nil,
          details_url: @distinct_details_url
        )

      %{duplicate_id: duplicate.id, distinct_id: distinct.id, ticketless_id: ticketless.id}
    end

    test "renders only the ticket chip when both urls match", %{
      conn: conn,
      duplicate_id: id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{id} a[rel='noopener sponsored'][href='#{@shared_url}']")
      refute has_element?(view, "#event-#{id} a[rel='noopener'][href='#{@shared_url}']")
    end

    test "renders both chips when the urls differ", %{conn: conn, distinct_id: id} do
      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{id} a[rel='noopener sponsored'][href='#{@shared_url}']")

      assert has_element?(
               view,
               "#event-#{id} a[rel='noopener'][href='#{@distinct_details_url}']"
             )
    end

    test "renders the info chip when the event has no ticket url", %{
      conn: conn,
      ticketless_id: id
    } do
      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(
               view,
               "#event-#{id} a[rel='noopener'][href='#{@distinct_details_url}']"
             )
    end

    test "treats a blank ticket url as absent rather than as a match", %{conn: conn} do
      event =
        insert(:event,
          venue: insert(:venue),
          date: DateHelpers.today_eastern(),
          title: "ev-blank",
          ticket_url: "",
          details_url: ""
        )

      {:ok, view, _html} = live(conn, ~p"/events")

      assert has_element?(view, "#event-#{event.id} a[rel='noopener'][href='']")
    end

    test "hides the duplicate info chip when sorting by venue", %{conn: conn, duplicate_id: id} do
      {:ok, view, _html} =
        conn |> put_connect_params(%{"sort_by" => "venue"}) |> live(~p"/events")

      assert has_element?(view, "#event-#{id} a[rel='noopener sponsored'][href='#{@shared_url}']")
      refute has_element?(view, "#event-#{id} a[rel='noopener'][href='#{@shared_url}']")
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
