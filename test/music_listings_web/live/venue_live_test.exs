defmodule MusicListingsWeb.VenueLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "index" do
    setup do
      venue_1 = insert(:venue, name: "Venue 1", street: "1 Street")

      _excluded_old_event =
        insert(:event, venue: venue_1, date: ~D[2024-07-30], title: "ev0")

      insert(:event, venue: venue_1, date: ~D[2024-08-01], title: "ev1")
      insert(:event, venue: venue_1, date: ~D[2024-08-01], title: "ev2")

      venue_2 = insert(:venue, name: "Venue 2", street: "2 Street")
      insert(:event, venue: venue_2, date: ~D[2024-08-02], title: "ev3")

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

    test "does not show venues that aren't crawled to anonymous visitors", %{conn: conn} do
      insert(:venue, name: "Dormant Venue", pull_events?: false)

      {:ok, view, html} = live(conn, ~p"/venues")

      refute html =~ "Dormant Venue"
      refute has_element?(view, "#inactive-venues")
      refute has_element?(view, "button[phx-click='toggle-pull-events']")
    end

    test "does not show crawl buttons to anonymous visitors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/venues")

      refute has_element?(view, "button[phx-click='crawl-all-venues']")
      refute has_element?(view, "button[phx-click='crawl-venue']")
    end
  end

  describe "index - logged in as admin" do
    setup :register_and_log_in_user

    setup do
      venue = insert(:venue, name: "Venue 1", street: "1 Street")
      dormant_venue = insert(:venue, name: "Dormant Venue", pull_events?: false)
      %{venue: venue, dormant_venue: dormant_venue}
    end

    test "shows crawl all and per-venue crawl buttons", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/venues")

      assert has_element?(view, "button[phx-click='crawl-all-venues']")
      assert has_element?(view, "button[phx-click='crawl-venue']")
    end

    test "lists venues that aren't crawled at the bottom", %{
      conn: conn,
      venue: venue,
      dormant_venue: dormant_venue
    } do
      {:ok, view, _html} = live(conn, ~p"/venues")

      assert has_element?(view, "#inactive-venues #venue-#{dormant_venue.id}")
      refute has_element?(view, "#inactive-venues #venue-#{venue.id}")
      assert has_element?(view, "#inactive-venues", "Not pulling events")
    end

    test "turns crawling a venue on", %{conn: conn, dormant_venue: dormant_venue} do
      {:ok, view, _html} = live(conn, ~p"/venues")

      html = view |> element("#pull-events-#{dormant_venue.id}") |> render_click()

      assert html =~ "Now pulling events for Dormant Venue."
      assert MusicListings.Repo.get!(MusicListingsSchema.Venue, dormant_venue.id).pull_events?
      refute has_element?(view, "#inactive-venues #venue-#{dormant_venue.id}")
      assert has_element?(view, "#venue-#{dormant_venue.id}")
    end

    test "turns crawling a venue off", %{conn: conn, venue: venue} do
      {:ok, view, _html} = live(conn, ~p"/venues")

      html = view |> element("#pull-events-#{venue.id}") |> render_click()

      assert html =~ "Stopped pulling events for Venue 1."
      refute MusicListings.Repo.get!(MusicListingsSchema.Venue, venue.id).pull_events?
      assert has_element?(view, "#inactive-venues #venue-#{venue.id}")
    end
  end

  describe "new - when not logged in" do
    test "redirects to log in when attempting to access page", %{conn: conn} do
      assert {:error, {:redirect, redirect_map}} = live(conn, ~p"/venues/new")

      assert redirect_map.to == "/users/log_in"
    end
  end

  describe "new - logged in" do
    setup :register_and_log_in_user

    test "saves submitted event with valid parameters", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/venues/new")
      assert has_element?(view, "h1", "New Venue")

      {:ok, _view, html} =
        view
        |> form("#venue-form", %{
          "venue" => %{
            "name" => "Bob's Bar",
            "street" => "123 Street",
            "city" => "TO",
            "province" => "ON",
            "country" => "CA",
            "postal_code" => "PC",
            "website" => "WS",
            "google_map_url" => "MURL",
            "parser_module_name" => "n/a",
            "pull_events?" => false
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/venues")

      assert html =~ "Venue created."
    end

    test "displays errors with invalid attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/venues/new")

      view
      |> form("#venue-form", %{"venue" => %{}})

      assert view
             |> form("#venue-form", %{"venue" => %{}})
             |> render_submit() =~ "can&#39;t be blank"
    end
  end
end
