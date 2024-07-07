defmodule MusicListings.CrawlerTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler
  alias MusicListings.Parsing.DanforthMusicHallParser
  alias MusicListings.Parsing.VelvetUndergroundParser
  alias MusicListings.Repo
  alias MusicListingsSchema.Event

  # This is a very naive test... we just check the number of
  # events inserted
  describe "crawl/1" do
    test "expected number of events are inserted" do
      parsers = [DanforthMusicHallParser, VelvetUndergroundParser]
      Crawler.crawl(parsers)

      assert 124 = Repo.aggregate(Event, :count)
    end
  end
end
