defmodule MusicListings.CrawlerTest do
  @moduledoc """
  These are pretty naive tests, might want to enhance them down the road
  """
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler
  alias MusicListings.Crawler.CrawlSummary
  alias MusicListings.Parsing.DanforthMusicHallParser
  alias MusicListings.Parsing.VelvetUndergroundParser
  alias MusicListings.Repo
  alias MusicListingsSchema.Event

  describe "crawl/1" do
    test "expected number of events are inserted" do
      parsers = [DanforthMusicHallParser, VelvetUndergroundParser]
      Crawler.crawl(parsers)

      assert 124 = Repo.aggregate(Event, :count)
    end
  end

  describe "crawl_summary/1" do
    setup do
      parsers = [DanforthMusicHallParser, VelvetUndergroundParser]
      payloads = Crawler.crawl(parsers)

      %{payloads: payloads}
    end

    test "summarizes the results of a crawl", %{payloads: payloads} do
      assert %CrawlSummary{
               new: 124,
               updated: 0,
               duplicate: 0,
               parse_errors: 0,
               errors: 0,
               parse_errors_dump: [],
               errors_dump: []
             } == Crawler.crawl_summary(payloads)
    end
  end
end
