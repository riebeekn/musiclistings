defmodule MusicListings.Affiliates.TicketNetworkTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Affiliates.TicketNetwork
  alias MusicListings.Repo
  alias MusicListingsSchema.Event

  # Matches the Horseshoe Tavern item in test/data/ticket_network/page_1.json,
  # whose catalog date is a day before the show.
  @today ~D[2026-07-25]
  @show_date ~D[2026-11-08]

  # Venues are created by migrations rather than factories, and the matcher
  # resolves them by parser module name, so use the real row.
  defp horseshoe_venue do
    Repo.get_by!(MusicListingsSchema.Venue, parser_module_name: "HorseshoeTavernParser")
  end

  defp hovvdy_event(venue, attrs \\ []) do
    insert(
      :event,
      Keyword.merge([venue: venue, title: "Hovvdy", date: @show_date, openers: []], attrs)
    )
  end

  describe "run/1" do
    test "writes the affiliate url onto a matched event" do
      event = hovvdy_event(horseshoe_venue())

      {:ok, stats} = TicketNetwork.run(today: @today)

      assert stats.linked == 1
      assert Repo.get!(Event, event.id).ticketnetwork_url =~ "goto.ticketnetwork.com"
    end

    test "prefers the lowest catalog item id when a show has duplicate products" do
      # The catalog lists this show twice, as products 1001 and 1000.
      event = hovvdy_event(horseshoe_venue())

      {:ok, _stats} = TicketNetwork.run(today: @today)

      assert Repo.get!(Event, event.id).ticketnetwork_url =~ "prodsku=1000"
    end

    test "clears the link when an event no longer matches the catalog" do
      venue = horseshoe_venue()

      event =
        hovvdy_event(venue,
          title: "Someone Not In The Catalog",
          ticketnetwork_url: "https://goto.ticketnetwork.com/c/stale"
        )

      {:ok, stats} = TicketNetwork.run(today: @today)

      assert stats.cleared == 1
      assert Repo.get!(Event, event.id).ticketnetwork_url == nil
    end

    test "links events locked from updates - the lock only guards crawled details" do
      event =
        hovvdy_event(horseshoe_venue(),
          locked_from_updates?: true,
          ticketnetwork_url: nil
        )

      {:ok, stats} = TicketNetwork.run(today: @today)

      assert stats.linked == 1
      assert Repo.get!(Event, event.id).ticketnetwork_url =~ "goto.ticketnetwork.com"
    end

    test "is idempotent" do
      hovvdy_event(horseshoe_venue())

      {:ok, _first} = TicketNetwork.run(today: @today)
      {:ok, second} = TicketNetwork.run(today: @today)

      assert second.linked == 0
      assert second.cleared == 0
    end

    test "ignores events at venues the catalog covers but on other dates" do
      event = hovvdy_event(horseshoe_venue(), date: ~D[2026-12-25])

      {:ok, _stats} = TicketNetwork.run(today: @today)

      assert Repo.get!(Event, event.id).ticketnetwork_url == nil
    end

    test "ignores past events" do
      event = hovvdy_event(horseshoe_venue(), date: ~D[2026-07-24])

      {:ok, stats} = TicketNetwork.run(today: @today)

      assert stats.linked == 0
      assert Repo.get!(Event, event.id).ticketnetwork_url == nil
    end

    test "counts catalog items at venues we don't track" do
      horseshoe_venue()

      {:ok, stats} = TicketNetwork.run(today: @today)

      # The Koerner Hall item in page_2.json.
      assert stats.untracked_items == 1
    end

    test "links the night the catalog is for and reports the run around it" do
      venue = horseshoe_venue()
      first = hovvdy_event(venue, date: @show_date)
      second = hovvdy_event(venue, date: Date.add(@show_date, 1))

      {:ok, stats} = TicketNetwork.run(today: @today)

      assert stats.linked == 1
      assert Repo.get!(Event, first.id).ticketnetwork_url =~ "goto.ticketnetwork.com"
      assert Repo.get!(Event, second.id).ticketnetwork_url == nil
      assert [%{title: "Hovvdy", dates: [_first, _second]}] = stats.consecutive_runs
    end

    test "skips when no credentials are configured" do
      original = Application.get_env(:music_listings, :ticket_network)
      Application.put_env(:music_listings, :ticket_network, account_sid: nil, auth_token: nil)
      on_exit(fn -> Application.put_env(:music_listings, :ticket_network, original) end)

      assert TicketNetwork.run(today: @today) == {:ok, :skipped}
    end

    test "dry runs report without writing" do
      event = hovvdy_event(horseshoe_venue())

      {:ok, stats} = TicketNetwork.run(today: @today, dry_run: true)

      assert stats.linked == 1
      assert Repo.get!(Event, event.id).ticketnetwork_url == nil
    end
  end

  describe "run_quietly/1" do
    test "returns nil rather than raising when the catalog is unreachable" do
      original = Application.get_env(:music_listings, :ticket_network)

      Application.put_env(:music_listings, :ticket_network,
        account_sid: "unknown_account_sid",
        auth_token: "test_auth_token"
      )

      on_exit(fn -> Application.put_env(:music_listings, :ticket_network, original) end)

      assert TicketNetwork.run_quietly(today: @today) == nil
    end
  end
end
