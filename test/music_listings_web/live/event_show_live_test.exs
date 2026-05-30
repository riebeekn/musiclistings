defmodule MusicListingsWeb.EventLive.ShowTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "show" do
    setup do
      venue = insert(:venue)

      event =
        insert(:event,
          venue: venue,
          title: "Dream Theater Live",
          headliner: "Dream Theater",
          openers: ["Haken"],
          date: ~D[2026-06-01],
          time: ~T[20:00:00],
          ticket_url: "https://tickets.example.com/dt"
        )

      %{event: event, venue: venue}
    end

    test "renders event details", %{conn: conn, event: event, venue: venue} do
      {:ok, _view, html} =
        live(conn, ~p"/events/#{event.id}/dream-theater-live")

      assert html =~ "Dream Theater Live"
      assert html =~ "Haken"
      _venue = venue
    end

    test "injects MusicEvent JSON-LD", %{conn: conn, event: event} do
      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/dream-theater-live")

      assert html =~ ~s(application/ld+json)
      assert html =~ ~s("@type":"MusicEvent")
      assert html =~ "Dream Theater Live"
    end

    test "redirects to canonical slug when slug is wrong", %{conn: conn, event: event} do
      assert {:error, {:live_redirect, %{to: to}}} =
               live(conn, ~p"/events/#{event.id}/wrong-slug")

      assert to =~ "/events/#{event.id}/dream-theater-live"
    end

    test "redirects to canonical slug when slug is missing", %{conn: conn, event: event} do
      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/events/#{event.id}")
      assert to =~ "/events/#{event.id}/dream-theater-live"
    end

    test "returns 404 for missing event", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/events/999999/anything")
      end
    end

    test "renders a past event with a notice", %{conn: conn, venue: venue} do
      # mock "today" in test env is 2024-08-01, so this date is in the past
      event = insert(:event, venue: venue, title: "Past Show", date: ~D[2024-07-01])

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/past-show")

      assert html =~ "Past Show"
      assert html =~ "This event has already taken place."
    end

    test "renders a soft-deleted upcoming event with a notice", %{conn: conn, event: event} do
      {:ok, _deleted} =
        MusicListingsSchema.Event
        |> MusicListings.Repo.get!(event.id)
        |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> MusicListings.Repo.update()

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/dream-theater-live")

      assert html =~ "Dream Theater Live"
      assert html =~ "This event is no longer listed"
    end
  end
end
