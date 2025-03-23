defmodule MusicListingsWeb.EventLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicListings.EventsFixtures

  describe "index" do
    setup do
      venue = insert(:venue)
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

  describe "index - logged in as admin" do
    setup :register_and_log_in_user

    setup do
      venue = insert(:venue)
      event = EventsFixtures.event_fixture(venue, date: ~D[2024-08-01])
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
