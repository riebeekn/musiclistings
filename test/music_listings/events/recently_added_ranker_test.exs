defmodule MusicListings.Events.RecentlyAddedRankerTest do
  use ExUnit.Case, async: true

  alias MusicListings.Events.RecentlyAddedRanker
  alias MusicListingsSchema.Event

  @now ~U[2024-08-01 12:00:00Z]

  # Build an in-memory Event struct. Working with plain structs (rather than DB rows)
  # lets us control inserted_at directly, which the schema would otherwise autogenerate.
  defp event(attrs) do
    defaults = %{
      id: System.unique_integer([:positive]),
      venue_id: 1,
      date: ~D[2024-08-10],
      title: "A Show",
      time: ~T[20:00:00],
      ticket_url: nil,
      inserted_at: @now
    }

    struct!(Event, Map.merge(defaults, Map.new(attrs)))
  end

  defp days_ago(n), do: DateTime.add(@now, -n, :day)

  describe "rank/3" do
    test "returns an empty list for no candidates" do
      assert RecentlyAddedRanker.rank([], @now) == []
    end

    test "caps a single venue at max_per_venue so it cannot dominate" do
      events =
        for i <- 1..10 do
          event(venue_id: 1, title: "Show #{i}", ticket_url: "https://tickets/#{i}")
        end

      assert length(RecentlyAddedRanker.rank(events, @now, max_per_venue: 3)) == 3
    end

    test "still includes smaller venues alongside a backlog-dumping venue" do
      busy = for i <- 1..10, do: event(venue_id: 1, title: "Busy #{i}", ticket_url: "https://t")
      small = event(venue_id: 2, title: "Small", ticket_url: nil)

      result = RecentlyAddedRanker.rank([small | busy], @now, max_per_venue: 3)

      assert Enum.any?(result, &(&1.venue_id == 2))
    end

    test "a brand-new non-ticketed show outranks an older ticketed show" do
      fresh = event(venue_id: 1, title: "Fresh", ticket_url: nil, inserted_at: @now)

      older =
        event(venue_id: 2, title: "Older", ticket_url: "https://t", inserted_at: days_ago(5))

      assert [%Event{title: "Fresh"}, %Event{title: "Older"}] =
               RecentlyAddedRanker.rank([older, fresh], @now)
    end

    test "a more recently added free show outranks an older ticketed show by one day" do
      older =
        event(venue_id: 2, title: "Older", ticket_url: "https://t", inserted_at: days_ago(1))

      newer = event(venue_id: 1, title: "Newer", ticket_url: nil, inserted_at: @now)

      assert [%Event{title: "Newer"}, %Event{title: "Older"}] =
               RecentlyAddedRanker.rank([older, newer], @now)
    end

    test "a ticketed show outranks a non-ticketed show of the same age" do
      ticketed = event(venue_id: 1, title: "Ticketed", ticket_url: "https://t")
      free = event(venue_id: 2, title: "Free", ticket_url: nil)

      assert [%Event{title: "Ticketed"}, %Event{title: "Free"}] =
               RecentlyAddedRanker.rank([free, ticketed], @now)
    end

    test "collapses multiple showtimes of one show into a single capped slot" do
      # Show X has two showtimes; show Y is a second show at the same venue.
      x1 = event(venue_id: 1, title: "X", time: ~T[18:00:00], inserted_at: @now)
      x2 = event(venue_id: 1, title: "X", time: ~T[21:00:00], inserted_at: @now)
      y = event(venue_id: 1, title: "Y", inserted_at: days_ago(3))

      # With a cap of 1, only the top show is kept - but both of X's showtimes survive,
      # proving X occupied a single slot rather than two.
      result = RecentlyAddedRanker.rank([x1, x2, y], @now, max_per_venue: 1)

      assert result |> Enum.map(& &1.title) |> Enum.uniq() == ["X"]
      assert length(result) == 2
    end

    test "collapses a recurring show across dates into one slot showing the soonest date" do
      # Same venue/title on two dates - one event to the reader, not two.
      early = event(venue_id: 1, title: "Recurring", date: ~D[2024-08-10], inserted_at: @now)
      late = event(venue_id: 1, title: "Recurring", date: ~D[2024-08-17], inserted_at: @now)

      result = RecentlyAddedRanker.rank([late, early], @now)

      assert [%Event{title: "Recurring", date: ~D[2024-08-10]}] = result
    end

    test "respects the overall limit" do
      events = for i <- 1..6, do: event(venue_id: i, title: "Show #{i}")

      assert length(RecentlyAddedRanker.rank(events, @now, limit: 4)) == 4
    end

    test "orders tied scores deterministically by id (highest first)" do
      a = event(id: 1, venue_id: 1, title: "A", ticket_url: "https://t")
      b = event(id: 2, venue_id: 2, title: "B", ticket_url: "https://t")

      assert [%Event{id: 2}, %Event{id: 1}] = RecentlyAddedRanker.rank([a, b], @now)
    end
  end
end
