defmodule MusicListings.CrawlerTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event

  # These are pretty naive tests, might want to enhance them down the road
  describe "crawl/1" do
    test "expected number of events are inserted" do
      venue_1 = insert(:venue)

      assert {:ok,
              %CrawlSummary{
                new: 71,
                updated: 0,
                duplicate: 0,
                errors: 0
              }} = Crawler.crawl([venue_1])

      assert 71 = Repo.aggregate(Event, :count)
    end
  end

  describe "data_last_updated_on/0" do
    test "returns No data string when no data" do
      assert "No data" == Crawler.data_last_updated_on()
    end

    test "ignores nil completed_at records" do
      _cs1 =
        insert(:crawl_summary)
        |> Ecto.Changeset.change(%{completed_at: nil})
        |> Repo.update!()

      assert "No data" == Crawler.data_last_updated_on()
    end

    test "returns the most recent completed at time when data" do
      _cs1 =
        insert(:crawl_summary)
        |> Ecto.Changeset.change(%{completed_at: ~U[2022-08-07 19:11:40Z]})
        |> Repo.update!()

      _cs2 =
        insert(:crawl_summary)
        |> Ecto.Changeset.change(%{completed_at: ~U[2021-08-07 19:11:40Z]})
        |> Repo.update!()

      assert "Aug 07 2022" == Crawler.data_last_updated_on()
    end
  end
end
