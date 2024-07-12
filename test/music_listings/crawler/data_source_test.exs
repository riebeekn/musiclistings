defmodule MusicListings.Crawler.DataSourceTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.DataSource
  alias MusicListings.Parsing.DanforthMusicHallParser

  describe "retrieve_events/4" do
    test "returns payload populated with raw event" do
      payloads =
        DataSource.retrieve_events(
          DanforthMusicHallParser,
          DanforthMusicHallParser.source_url(),
          false
        )

      # Just check the number of payloads and that they are populated with
      # raw events
      assert 68 = Enum.count(payloads)
      assert Enum.all?(payloads, &(&1.raw_event != nil))
    end
  end
end
