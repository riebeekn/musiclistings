defmodule MusicListings.CurationTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Accounts.User
  alias MusicListings.Curation
  alias MusicListingsSchema.EventFlag
  alias MusicListingsUtilities.DateHelpers

  # DateHelpers.now/0 is frozen in test, so "upcoming" is relative to a fixed
  # today. Everything here is dated after it.
  defp upcoming_date(days_ahead \\ 7) do
    DateHelpers.today_eastern() |> Date.add(days_ahead)
  end

  defp admin, do: %User{role: :admin}

  describe "run/0 - non-event titles" do
    for title <- [
          "CLOSED MONDAY - WEDNESDAY",
          "TRANZAC CLOSED",
          "Private Booking",
          "PRIVATE EVENT",
          "CLOSED FOR A PRIVATE EVENT!",
          "Venue Rental",
          "TBA"
        ] do
      test "flags #{title}" do
        event = insert(:event, title: unquote(title), date: upcoming_date())

        Curation.run()

        assert [%EventFlag{type: :non_event_title, event_id: event_id}] =
                 Curation.list_open_flags()

        assert event_id == event.id
      end
    end

    # These read like status text to a loose regex but are real listings, and
    # flagging them would make the queue useless.
    for title <- [
          "KARAOKE THURSDAYS!",
          "Free F'all Open Mic",
          "Good Lovelies Holiday Concert",
          "Degrassi Trivia Night",
          "Open Stage - TBA"
        ] do
      test "does not flag #{title}" do
        insert(:event, title: unquote(title), date: upcoming_date())

        Curation.run()

        assert [] == Curation.list_open_flags()
      end
    end

    test "ignores deleted and past events" do
      insert(:event, title: "PRIVATE EVENT", date: upcoming_date(), deleted_at: DateHelpers.now())
      insert(:event, title: "PRIVATE EVENT", date: upcoming_date(-30))

      Curation.run()

      assert [] == Curation.list_open_flags()
    end
  end

  describe "run/0 - duplicates" do
    test "flags the same show listed twice at one venue" do
      venue = insert(:venue)
      date = upcoming_date()
      older = insert(:event, venue: venue, title: "Sara Bareilles", date: date)
      newer = insert(:event, venue: venue, title: "Sara Bareilles", date: date)

      Curation.run()

      assert [flag] = Curation.list_open_flags()
      assert flag.type == :duplicate_event
      # One row per pair, hung off the higher id.
      assert flag.event_id == newer.id
      assert flag.related_event_id == older.id
    end

    test "flags a show listed by two venues in the same building" do
      # Modelled on Lee's Palace and The Dance Cave, which is the room upstairs:
      # one building, two venue rows, street strings that don't match as text.
      # Named generically because the migrations seed the real venues.
      lees = insert(:venue, street: "529 Bloor St W")
      cave = insert(:venue, street: "529 Bloor Street West")
      date = upcoming_date()

      insert(:event, venue: lees, title: "Slow Teeth w/ Waxlimbs", date: date)
      insert(:event, venue: cave, title: "Slow Teeth with Waxlimbs", date: date)

      Curation.run()

      assert [%EventFlag{type: :duplicate_event}] = Curation.list_open_flags()
    end

    test "does not flag the same title at unrelated venues" do
      # A real multi-venue festival - the reason cross-venue pairs are excluded.
      one = insert(:venue, street: "1608 Dundas St W")
      two = insert(:venue, street: "1197 Dundas St West")
      date = upcoming_date()

      insert(:event, venue: one, title: "SECOND SUMMER FESTIVAL", date: date)
      insert(:event, venue: two, title: "SECOND SUMMER FESTIVAL", date: date)

      Curation.run()

      assert [] == Curation.list_open_flags()
    end

    test "does not flag the same title on different dates" do
      venue = insert(:venue)
      insert(:event, venue: venue, title: "Geese", date: upcoming_date(3))
      insert(:event, venue: venue, title: "Geese", date: upcoming_date(4))

      Curation.run()

      assert [] == Curation.list_open_flags()
    end

    test "does not flag two showtimes of one night" do
      # Normalization drops everything after the first ":", taking the showtime
      # with it and leaving the titles identical - the raw titles disagree.
      venue = insert(:venue)
      date = upcoming_date()

      insert(:event,
        venue: venue,
        title: "Canine Circus: Northern Lights - 4:30pm Show",
        date: date
      )

      insert(:event,
        venue: venue,
        title: "Canine Circus: Northern Lights - 7:30 show",
        date: date
      )

      Curation.run()

      assert [] == Curation.list_open_flags()
    end

    test "closes the flag when either side of the pair is deleted" do
      venue = insert(:venue)
      date = upcoming_date()
      insert(:event, venue: venue, title: "Kettama", date: date)
      newer = insert(:event, venue: venue, title: "Kettama", date: date)

      Curation.run()
      assert [_flag] = Curation.list_open_flags()

      {:ok, _deleted} = MusicListings.delete_event(admin(), newer.id)

      assert [] == Curation.list_open_flags()
    end
  end

  describe "run/0 - reconciliation" do
    setup do
      event = insert(:event, title: "PRIVATE EVENT", date: upcoming_date())
      %{event: event}
    end

    test "is idempotent", %{event: _event} do
      Curation.run()
      Curation.run()
      Curation.run()

      assert [_only_one] = Curation.list_open_flags()
      assert 1 == Repo.aggregate(EventFlag, :count)
    end

    test "deletes an open flag whose cause is gone", %{event: event} do
      Curation.run()
      assert [_flag] = Curation.list_open_flags()

      event |> Ecto.Changeset.change(%{title: "A Real Band"}) |> Repo.update!()
      Curation.run()

      assert [] == Curation.list_open_flags()
      assert 0 == Repo.aggregate(EventFlag, :count)
    end

    test "does not resurrect a dismissed flag", %{event: event} do
      Curation.run()
      {:ok, 1} = Curation.dismiss_flags(admin(), event.id)

      Curation.run()

      assert [] == Curation.list_open_flags()
      # The row survives, which is what stops it being raised again.
      assert 1 == Repo.aggregate(EventFlag, :count)
    end
  end

  describe "remove_redundant_room_listings/0" do
    # Named generically because the migrations seed the real venues.  The parser
    # module name is what identifies them.
    setup do
      %{
        lees: insert(:venue, parser_module_name: "LeesPalaceParser", street: "529 Bloor St W"),
        cave:
          insert(:venue, parser_module_name: "DanceCaveParser", street: "529 Bloor Street West")
      }
    end

    defp duplicate_pair(lees, cave, lees_opts \\ []) do
      date = upcoming_date()

      {insert(:event, [venue: lees, title: "Mango Szn", date: date] ++ lees_opts),
       insert(:event, venue: cave, title: "Mango Szn", date: date)}
    end

    test "soft-deletes the Lee's Palace listing and keeps The Dance Cave's", %{
      lees: lees,
      cave: cave
    } do
      {lees_event, cave_event} = duplicate_pair(lees, cave)
      Curation.run()

      assert [%{removed: removed, kept: kept}] = Curation.remove_redundant_room_listings()

      assert removed.id == lees_event.id
      assert kept.id == cave_event.id
      assert Repo.reload!(lees_event).deleted_at
      refute Repo.reload!(cave_event).deleted_at
      assert [] == Curation.list_open_flags()
    end

    test "removes the Lee's Palace listing whichever event was crawled first", %{
      lees: lees,
      cave: cave
    } do
      date = upcoming_date()
      cave_event = insert(:event, venue: cave, title: "Mango Szn", date: date)
      lees_event = insert(:event, venue: lees, title: "Mango Szn", date: date)
      Curation.run()

      Curation.remove_redundant_room_listings()

      assert Repo.reload!(lees_event).deleted_at
      refute Repo.reload!(cave_event).deleted_at
    end

    test "reports a listing once when it duplicates two others", %{lees: lees, cave: cave} do
      {lees_event, _cave_event} = duplicate_pair(lees, cave)
      insert(:event, title: "Mango Szn", date: lees_event.date, venue: cave)
      Curation.run()

      assert [%{removed: removed}] = Curation.remove_redundant_room_listings()
      assert removed.id == lees_event.id
    end

    test "leaves a restored listing alone", %{lees: lees, cave: cave} do
      {lees_event, _cave_event} = duplicate_pair(lees, cave)
      Curation.run()
      Curation.remove_redundant_room_listings()

      lees_event |> Repo.reload!() |> Ecto.Changeset.change(deleted_at: nil) |> Repo.update!()
      Curation.run()

      assert [] == Curation.remove_redundant_room_listings()
      refute Repo.reload!(lees_event).deleted_at
      assert [] == Curation.list_open_flags()
    end

    test "leaves a pair an admin has dismissed alone", %{lees: lees, cave: cave} do
      {lees_event, _cave_event} = duplicate_pair(lees, cave)
      Curation.run()
      {:ok, 1} = Curation.dismiss_flags(admin(), lees_event.id)

      assert [] == Curation.remove_redundant_room_listings()
      refute Repo.reload!(lees_event).deleted_at
    end

    test "leaves a locked listing in the review queue", %{lees: lees, cave: cave} do
      {lees_event, _cave_event} = duplicate_pair(lees, cave, locked_from_updates?: true)
      Curation.run()

      assert [] == Curation.remove_redundant_room_listings()
      refute Repo.reload!(lees_event).deleted_at
      assert [%EventFlag{}] = Curation.list_open_flags()
    end

    test "leaves different shows on the same date alone", %{lees: lees, cave: cave} do
      date = upcoming_date()
      lees_event = insert(:event, venue: lees, title: "Scott Helman", date: date)
      insert(:event, venue: cave, title: "Soda Stereo Tribute", date: date)
      Curation.run()

      assert [] == Curation.remove_redundant_room_listings()
      refute Repo.reload!(lees_event).deleted_at
    end

    test "leaves a Lee's Palace listing duplicated at Lee's Palace in the queue", %{lees: lees} do
      date = upcoming_date()
      older = insert(:event, venue: lees, title: "Mango Szn", date: date)
      insert(:event, venue: lees, title: "Mango Szn", date: date)
      Curation.run()

      assert [] == Curation.remove_redundant_room_listings()
      refute Repo.reload!(older).deleted_at
      assert [%EventFlag{}] = Curation.list_open_flags()
    end

    test "leaves duplicates in other buildings in the queue" do
      first = insert(:venue, parser_module_name: "RcmOneParser", street: "273 Bloor St W")
      second = insert(:venue, parser_module_name: "RcmTwoParser", street: "273 Bloor Street West")
      date = upcoming_date()
      event = insert(:event, venue: first, title: "Mango Szn", date: date)
      insert(:event, venue: second, title: "Mango Szn", date: date)
      Curation.run()

      assert [] == Curation.remove_redundant_room_listings()
      refute Repo.reload!(event).deleted_at
      assert [%EventFlag{}] = Curation.list_open_flags()
    end
  end

  describe "remove_redundant_room_listings_quietly/0" do
    test "returns what was removed" do
      lees = insert(:venue, parser_module_name: "LeesPalaceParser", street: "529 Bloor St W")

      cave =
        insert(:venue, parser_module_name: "DanceCaveParser", street: "529 Bloor Street West")

      date = upcoming_date()
      insert(:event, venue: lees, title: "Mango Szn", date: date)
      insert(:event, venue: cave, title: "Mango Szn", date: date)
      Curation.run()

      assert [%{removed: _removed, kept: _kept}] =
               Curation.remove_redundant_room_listings_quietly()
    end
  end

  describe "dismiss_flags/2" do
    setup do
      event = insert(:event, title: "PRIVATE EVENT", date: upcoming_date())
      Curation.run()
      %{event: event}
    end

    test "returns error when no user", %{event: event} do
      assert {:error, :not_allowed} == Curation.dismiss_flags(nil, event.id)
    end

    test "returns error when user not an admin", %{event: event} do
      assert {:error, :not_allowed} ==
               Curation.dismiss_flags(%User{role: :regular_user}, event.id)
    end

    test "dismisses the flag", %{event: event} do
      assert {:ok, 1} = Curation.dismiss_flags(admin(), event.id)
      assert [] == Curation.list_open_flags()
    end

    test "dismisses from either side of a pair" do
      venue = insert(:venue)
      date = upcoming_date()
      older = insert(:event, venue: venue, title: "BUNT.", date: date)
      insert(:event, venue: venue, title: "BUNT.", date: date)
      Curation.run()

      # The flag row hangs off the newer event; dismissing via the older one -
      # the `related_event_id` side - still settles the pair.
      assert {:ok, 1} = Curation.dismiss_flags(admin(), older.id)

      refute Enum.any?(Curation.list_open_flags(), &(&1.type == :duplicate_event))
    end
  end

  describe "flagged?/1" do
    test "is true for either side of a pair, false otherwise" do
      venue = insert(:venue)
      date = upcoming_date()
      older = insert(:event, venue: venue, title: "Geese", date: date)
      newer = insert(:event, venue: venue, title: "Geese", date: date)
      unflagged = insert(:event, title: "A Real Band", date: date)

      Curation.run()

      assert Curation.flagged?(older.id)
      assert Curation.flagged?(newer.id)
      refute Curation.flagged?(unflagged.id)
    end
  end

  describe "venue_group_key/1" do
    test "groups rooms in one building despite differing street strings" do
      assert Curation.venue_group_key(%{street: "529 Bloor St W"}) ==
               Curation.venue_group_key(%{street: "529 Bloor Street West"})
    end

    test "keeps separate addresses apart" do
      refute Curation.venue_group_key(%{street: "1608 Dundas St W"}) ==
               Curation.venue_group_key(%{street: "1197 Dundas St West"})
    end

    test "falls back to the whole address when there is no street number" do
      assert Curation.venue_group_key(%{street: "Exhibition Place"}) == "exhibition place"
    end
  end
end
