defmodule MusicListingsWeb.SubmittedEventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicListings.VenuesFixtures

  describe "index - when not logged in" do
    test "redirects to log in when attempting to access page", %{conn: conn} do
      assert {:error, {:redirect, redirect_map}} = live(conn, ~p"/submitted_events")

      assert redirect_map.to == "/users/log_in"
    end
  end

  describe "index - logged in" do
    setup :register_and_log_in_user

    setup do
      venue = VenuesFixtures.venue_fixture()

      e0 = insert(:submitted_event, date: ~D[2024-07-30], title: "ev0", venue: venue.name)
      e1 = insert(:submitted_event, date: ~D[2024-08-01], title: "ev1")

      %{e0_id: e0.id, e1_id: e1.id}
    end

    test "displays events", %{conn: conn, e0_id: e0_id, e1_id: e1_id} do
      {:ok, view, _html} = live(conn, ~p"/submitted_events")

      # check the elements are present
      assert has_element?(view, "#event-#{e0_id}")
      assert has_element?(view, "#event-#{e1_id}")

      # should all have the approve button
      assert has_element?(
               view,
               "[phx-click=\"approve-submitted-event\"][phx-value-id=\"#{e0_id}\"]"
             )

      assert has_element?(
               view,
               "[phx-click=\"approve-submitted-event\"][phx-value-id=\"#{e1_id}\"]"
             )
    end

    test "can approve a submitted event", %{conn: conn, e0_id: e0_id} do
      {:ok, view, _html} = live(conn, ~p"/submitted_events")

      view
      |> element("#event-#{e0_id} button")
      |> render_click()

      refute has_element?(
               view,
               "[phx-click=\"approve-submitted-event\"][phx-value-id=\"#{e0_id}\"]"
             )
    end

    test "show an error when the venue does not exist", %{conn: conn, e1_id: e1_id} do
      {:ok, view, _html} = live(conn, ~p"/submitted_events")

      view
      |> element("#event-#{e1_id} button")
      |> render_click()

      assert render(view) =~ "Venue not found"
    end
  end
end
