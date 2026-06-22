defmodule MusicListingsWeb.SubmittedEventEditLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "edit - when not logged in" do
    test "redirects to log in", %{conn: conn} do
      submitted_event = insert(:submitted_event)

      assert {:error, {:redirect, redirect_map}} =
               live(conn, ~p"/submitted_events/#{submitted_event.id}/edit")

      assert redirect_map.to == "/users/log_in"
    end
  end

  describe "edit - logged in" do
    setup :register_and_log_in_user

    setup do
      submitted_event = insert(:submitted_event, venue: "The Village Vanguard")
      %{submitted_event: submitted_event}
    end

    test "renders the form pre-populated with the submission", %{
      conn: conn,
      submitted_event: submitted_event
    } do
      {:ok, _view, html} = live(conn, ~p"/submitted_events/#{submitted_event.id}/edit")

      assert html =~ "Edit Submission"
      assert html =~ submitted_event.title
      assert html =~ submitted_event.venue
    end

    test "redirects when the submitted event does not exist", %{conn: conn} do
      assert {:error, {:live_redirect, redirect_map}} =
               live(conn, ~p"/submitted_events/-1/edit")

      assert redirect_map.to == "/submitted_events"
    end

    test "redirects when the id is not a valid integer", %{conn: conn} do
      assert {:error, {:live_redirect, redirect_map}} =
               live(conn, ~p"/submitted_events/abc/edit")

      assert redirect_map.to == "/submitted_events"
    end

    test "shows a warning hint when the venue does not match an existing venue", %{
      conn: conn,
      submitted_event: submitted_event
    } do
      {:ok, view, _html} = live(conn, ~p"/submitted_events/#{submitted_event.id}/edit")

      html =
        view
        |> form("#submitted-event-form", submitted_event: %{venue: "No Such Venue"})
        |> render_change()

      assert html =~ "No venue matches"
    end

    test "shows a match hint when the venue matches an existing venue", %{
      conn: conn,
      submitted_event: submitted_event
    } do
      insert(:venue, name: "Matching Venue")

      {:ok, view, _html} = live(conn, ~p"/submitted_events/#{submitted_event.id}/edit")

      html =
        view
        |> form("#submitted-event-form", submitted_event: %{venue: "Matching Venue"})
        |> render_change()

      assert html =~ "Matches &#39;Matching Venue&#39;"
    end

    test "saving a corrected venue updates the submission and redirects", %{
      conn: conn,
      submitted_event: submitted_event
    } do
      insert(:venue, name: "Matching Venue")

      {:ok, view, _html} = live(conn, ~p"/submitted_events/#{submitted_event.id}/edit")

      view
      |> form("#submitted-event-form", submitted_event: %{venue: "Matching Venue"})
      |> render_submit()

      assert_redirect(view, ~p"/submitted_events")

      assert MusicListings.Repo.reload(submitted_event).venue == "Matching Venue"
    end

    test "cancel redirects back to the list", %{conn: conn, submitted_event: submitted_event} do
      {:ok, view, _html} = live(conn, ~p"/submitted_events/#{submitted_event.id}/edit")

      view
      |> element("button", "Cancel")
      |> render_click()

      assert_redirect(view, ~p"/submitted_events")
    end
  end
end
