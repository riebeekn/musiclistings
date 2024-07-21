defmodule MusicListings.CrawlerTest do
  @moduledoc """
  These are pretty naive tests, might want to enhance them down the road
  """
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler
  alias MusicListings.Parsing.DanforthMusicHallParser
  alias MusicListings.Parsing.VelvetUndergroundParser
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event

  describe "crawl/1" do
    test "expected number of events are inserted" do
      parsers = [DanforthMusicHallParser, VelvetUndergroundParser]

      assert {:ok,
              %CrawlSummary{
                new: 124,
                updated: 0,
                duplicate: 0,
                parse_errors: 0
              }} = Crawler.crawl(parsers)

      assert 124 = Repo.aggregate(Event, :count)
    end
  end
end
