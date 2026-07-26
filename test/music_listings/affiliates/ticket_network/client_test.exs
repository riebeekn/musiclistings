defmodule MusicListings.Affiliates.TicketNetwork.ClientTest do
  use ExUnit.Case, async: true

  alias MusicListings.Affiliates.TicketNetwork.Client
  alias MusicListings.Affiliates.TicketNetwork.Item

  @today ~D[2026-07-25]

  describe "fetch_items/1" do
    test "walks every page reported by the catalog" do
      {:ok, items} = Client.fetch_items(@today)

      # Two items on page 1, three on page 2, one of which is junk.
      assert length(items) == 4
      assert Enum.map(items, & &1.catalog_item_id) == ["1001", "1002", "1000", "1003"]
    end

    test "decodes the repurposed catalog fields" do
      {:ok, [item | _rest]} = Client.fetch_items(@today)

      assert %Item{
               catalog_item_id: "1001",
               name: "Hovvdy",
               venue_label: "Horseshoe Tavern",
               date: ~D[2026-11-07]
             } = item

      assert item.url =~ "goto.ticketnetwork.com"
    end

    test "keeps the catalog date as written rather than normalizing to UTC" do
      # The catalog's times are 19:00/20:00 Eastern placeholders, so converting
      # to UTC would roll every date forward a day and hide the offset the
      # matcher exists to correct.
      {:ok, items} = Client.fetch_items(@today)

      assert Enum.find(items, &(&1.catalog_item_id == "1002")).date == ~D[2026-09-10]
    end

    test "drops rows with nonsense dates" do
      {:ok, items} = Client.fetch_items(@today)

      refute Enum.any?(items, &(&1.name == "Malcolm Todd"))
    end

    test "returns an error when credentials are absent" do
      original = Application.get_env(:music_listings, :ticket_network)
      Application.put_env(:music_listings, :ticket_network, account_sid: nil, auth_token: nil)
      on_exit(fn -> Application.put_env(:music_listings, :ticket_network, original) end)

      assert Client.fetch_items(@today) == {:error, :not_configured}
      refute Client.configured?()
    end

    test "fails rather than returning a partial catalog when a page is unreachable" do
      # A short read would look to the matcher like a batch of delisted events
      # and would clear links that are still live.
      original = Application.get_env(:music_listings, :ticket_network)

      Application.put_env(:music_listings, :ticket_network,
        account_sid: "unknown_account_sid",
        auth_token: "test_auth_token"
      )

      on_exit(fn -> Application.put_env(:music_listings, :ticket_network, original) end)

      assert {:error, _reason} = Client.fetch_items(@today)
    end
  end

  describe "configured?/0" do
    test "is true when both credentials are present" do
      assert Client.configured?()
    end
  end
end
