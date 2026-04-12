defmodule MusicListingsWeb.FeedControllerTest do
  use MusicListingsWeb.ConnCase, async: true

  alias MusicListingsUtilities.DateHelpers

  describe "GET /feed.xml" do
    test "returns an RSS feed with upcoming events", %{conn: conn} do
      today = DateHelpers.today_eastern()
      venue = insert(:venue, name: "Feed Venue")
      event = insert(:event, venue: venue, date: today, title: "Feed Event")

      conn = get(conn, ~p"/feed.xml")

      assert response_content_type(conn, :xml)
      body = response(conn, 200)

      assert body =~ "<?xml"
      assert body =~ "<rss"
      assert body =~ "<channel>"
      assert body =~ "Toronto Music Listings"
      assert body =~ "Feed Event"
      assert body =~ "/events/#{event.id}/feed-event"
      assert body =~ ~s(<guid isPermaLink="true">)
    end

    test "excludes past events", %{conn: conn} do
      today = DateHelpers.today_eastern()
      past_event = insert(:event, date: Date.add(today, -10), title: "Old Show")

      conn = get(conn, ~p"/feed.xml")
      body = response(conn, 200)

      refute body =~ "/events/#{past_event.id}/"
    end

    test "excludes deleted events", %{conn: conn} do
      today = DateHelpers.today_eastern()

      deleted_event =
        insert(:event,
          date: today,
          title: "Deleted Show",
          deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)
        )

      conn = get(conn, ~p"/feed.xml")
      body = response(conn, 200)

      refute body =~ "/events/#{deleted_event.id}/"
    end
  end
end
