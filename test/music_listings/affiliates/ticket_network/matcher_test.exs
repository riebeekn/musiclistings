defmodule MusicListings.Affiliates.TicketNetwork.MatcherTest do
  use ExUnit.Case, async: true

  alias MusicListings.Affiliates.TicketNetwork.Item
  alias MusicListings.Affiliates.TicketNetwork.Matcher

  @venue_ids %{"HorseshoeTavernParser" => 8, "RoyThomsonHallParser" => 12}

  defp item(attrs) do
    defaults = %Item{
      catalog_item_id: "1001",
      name: "Hovvdy",
      venue_label: "Horseshoe Tavern",
      date: ~D[2026-11-07],
      url: "https://goto.ticketnetwork.com/c/1001"
    }

    struct!(defaults, attrs)
  end

  defp event(attrs) do
    defaults = %{
      id: 1,
      venue_id: 8,
      date: ~D[2026-11-08],
      title: "Hovvdy",
      headliner: nil,
      openers: []
    }

    Map.merge(defaults, Map.new(attrs))
  end

  describe "match/3 date handling" do
    test "matches an event on the day after the catalog date" do
      result = Matcher.match([item([])], [event([])], @venue_ids)

      assert [%{event_id: 1, url: "https://goto.ticketnetwork.com/c/1001"}] = result.matches
    end

    test "does not match an event on the catalog date itself" do
      # The offset is fixed rather than tried alongside 0: an unshifted date is
      # TicketNetwork data we have no reason to trust, and allowing it would put
      # every night of a run back in reach of its neighbour's listing.
      result = Matcher.match([item([])], [event(date: ~D[2026-11-07])], @venue_ids)

      assert result.matches == []
    end

    test "does not match a date outside the offset" do
      result = Matcher.match([item([])], [event(date: ~D[2026-11-10])], @venue_ids)

      assert result.matches == []
      assert [%Item{}] = result.unmatched_items
    end

    test "a right date with a wrong title is not a match" do
      result = Matcher.match([item([])], [event(title: "Thesaurus Rex")], @venue_ids)

      assert result.matches == []
    end
  end

  describe "match/3 title normalization" do
    test "strips TicketNetwork's role suffixes" do
      result =
        Matcher.match([item(name: "Cardinals - Band")], [event(title: "Cardinals")], @venue_ids)

      assert [%{event_id: 1}] = result.matches
    end

    test "reconciles the Toronto Symphony Orchestra naming" do
      items = [item(name: "Toronto Symphony Orchestra: Messiah", venue_label: "Roy Thomson Hall")]
      events = [event(venue_id: 12, title: "TSO - Messiah")]

      assert [%{event_id: 1}] = Matcher.match(items, events, @venue_ids).matches
    end

    test "folds accents" do
      result = Matcher.match([item(name: "Dadi Freyr")], [event(title: "Daði Freyr")], @venue_ids)

      assert [%{event_id: 1}] = result.matches
    end

    test "ignores a trailing tour name" do
      events = [event(title: "Altin Gün - AMERICA TOUR 2026")]

      assert [%{event_id: 1}] =
               Matcher.match([item(name: "Altin Gün")], events, @venue_ids).matches
    end

    test "matches against the headliner and openers, not just the title" do
      events = [event(title: "Kevin Atwater", openers: ["Jessie Mazin"])]

      assert [%{event_id: 1}] =
               Matcher.match([item(name: "Jessie Mazin")], events, @venue_ids).matches
    end

    test "does not match titles that differ only by a number" do
      # "Piano Concerto No. 3" and "No. 4" are one character apart, which
      # character-level similarity alone scores well above the threshold.
      items = [
        item(
          name: "Toronto Symphony Orchestra: Rachmaninoff's Piano Concerto No. 4",
          venue_label: "Roy Thomson Hall"
        )
      ]

      events = [event(venue_id: 12, title: "TSO - Rachmaninoff Piano Concerto No. 3")]

      assert Matcher.match(items, events, @venue_ids).matches == []
    end

    test "tolerates a number on only one side" do
      events = [event(title: "Bingo Loco Toronto @ Annabel's Late Show (9:30PM)")]

      assert [%{event_id: 1}] =
               Matcher.match([item(name: "Bingo Loco")], events, @venue_ids).matches
    end
  end

  describe "match/3 consecutive nights" do
    test "gives each night of a run its own listing, and reports the run" do
      items = [item(date: ~D[2026-11-07]), item(catalog_item_id: "1002", date: ~D[2026-11-08])]
      events = [event(id: 1, date: ~D[2026-11-08]), event(id: 2, date: ~D[2026-11-09])]

      result = Matcher.match(items, events, @venue_ids)

      assert [
               %{event_id: 1, catalog_item_id: "1001"},
               %{event_id: 2, catalog_item_id: "1002"}
             ] = result.matches

      assert [%{venue_id: 8, title: "Hovvdy", dates: [~D[2026-11-08], ~D[2026-11-09]]}] =
               result.consecutive_runs
    end

    test "links only the night a listing is actually for" do
      # TicketNetwork often carries just one night of a run; the other night
      # goes unlinked rather than borrowing its neighbour's listing.
      events = [event(id: 1, date: ~D[2026-11-08]), event(id: 2, date: ~D[2026-11-09])]

      result = Matcher.match([item(date: ~D[2026-11-08])], events, @venue_ids)

      assert [%{event_id: 2}] = result.matches
    end

    test "reports only the abutting nights of a residency" do
      # A one-off date months later carries none of a run's risk.
      events = [
        event(id: 1, date: ~D[2026-11-08]),
        event(id: 2, date: ~D[2026-11-09]),
        event(id: 3, date: ~D[2027-04-10])
      ]

      result = Matcher.match([item(date: ~D[2027-04-09])], events, @venue_ids)

      assert [%{event_id: 3}] = result.matches
      assert [%{dates: [~D[2026-11-08], ~D[2026-11-09]]}] = result.consecutive_runs
    end
  end

  describe "match/3 ambiguity" do
    test "skips a night where two of our events match equally well" do
      events = [event(id: 1), event(id: 2, title: "Hovvdy")]

      result = Matcher.match([item([])], events, @venue_ids)

      assert result.matches == []
    end

    test "picks the better of two candidates on the same night" do
      events = [event(id: 1, title: "Hovvdy"), event(id: 2, title: "Someone Else Entirely")]

      assert [%{event_id: 1}] = Matcher.match([item([])], events, @venue_ids).matches
    end

    test "collapses duplicate catalog products onto one event, deterministically" do
      items = [item(catalog_item_id: "1001"), item(catalog_item_id: "1000")]

      result = Matcher.match(items, [event([])], @venue_ids)

      assert [%{event_id: 1, catalog_item_id: "1000"}] = result.matches
    end
  end

  describe "match/3 venue resolution" do
    test "counts items at venues we don't track" do
      result = Matcher.match([item(venue_label: "Koerner Hall")], [event([])], @venue_ids)

      assert result.matches == []
      assert result.untracked_labels == %{"Koerner Hall" => 1}
    end

    test "does not match an event at a different venue on the right date" do
      result = Matcher.match([item([])], [event(venue_id: 12)], @venue_ids)

      assert result.matches == []
    end
  end

  describe "normalize/1" do
    test "reduces a title to its identifying words" do
      assert Matcher.normalize("The Hovvdy Band - Live") == "hovvdy band"
    end

    test "keeps a short leading segment rather than collapsing to it" do
      assert Matcher.normalize("TSO - Messiah") == "tso messiah"
    end

    test "handles nil" do
      assert Matcher.normalize(nil) == ""
    end
  end

  describe "score/2" do
    test "is 1.0 for titles that normalize identically" do
      assert Matcher.score("Hovvdy", "hovvdy  ") == 1.0
    end

    test "is 0.0 when either side is empty" do
      assert Matcher.score("Hovvdy", nil) == 0.0
    end

    test "clears the threshold for a containment match" do
      assert Matcher.score("Wesley Joseph", "Wesley Joseph and Friends") >= Matcher.threshold()
    end

    test "stays below the threshold for unrelated acts" do
      assert Matcher.score("Hovvdy", "Thesaurus Rex") < Matcher.threshold()
    end
  end
end
