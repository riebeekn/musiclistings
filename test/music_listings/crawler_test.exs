defmodule MusicListings.CrawlerTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler
  alias MusicListings.CrawlErrorFixtures
  alias MusicListings.CrawlSummariesFixtures
  alias MusicListings.Repo
  alias MusicListings.VenuesFixtures
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.IgnoredEvent

  # These are pretty naive tests, might want to enhance them down the road
  describe "crawl/1" do
    test "expected number of events are inserted" do
      danforth = VenuesFixtures.venue_fixture()

      velvet_underground =
        VenuesFixtures.venue_fixture(%{
          name: "Velvet Underground",
          parser_module_name: "VelvetUndergroundParser"
        })

      assert {:ok,
              %CrawlSummary{
                new: 124,
                updated: 0,
                duplicate: 0,
                parse_errors: 0
              }} = Crawler.crawl([danforth, velvet_underground])

      assert 124 = Repo.aggregate(Event, :count)
    end
  end

  describe "ignore_crawl_error/1" do
    setup do
      dakota_tavern =
        VenuesFixtures.venue_fixture(%{
          name: "The Dakota Tavern",
          parser_module_name: "DakotaTavernParser"
        })

      crawl_summary = CrawlSummariesFixtures.crawl_summary_fixture()
      crawl_error = CrawlErrorFixtures.crawl_error_fixture(dakota_tavern, crawl_summary)

      %{crawl_error: crawl_error, dakota_tavern: dakota_tavern}
    end

    test "add an ignored event error", %{crawl_error: crawl_error, dakota_tavern: dakota_tavern} do
      dakota_tavern_id = dakota_tavern.id

      assert %IgnoredEvent{ignored_event_id: "freefall_open_mic", venue_id: ^dakota_tavern_id} =
               Crawler.ignore_crawl_error(crawl_error.id)
    end
  end

  describe "data_last_updated_on/0" do
    test "returns No data string when no data" do
      assert "No data" == Crawler.data_last_updated_on()
    end

    test "ignores nil completed_at records" do
      _cs1 =
        CrawlSummariesFixtures.crawl_summary_fixture()
        |> Ecto.Changeset.change(%{completed_at: nil})
        |> Repo.update!()

      assert "No data" == Crawler.data_last_updated_on()
    end

    test "returns the most recent completed at time when data" do
      _cs1 =
        CrawlSummariesFixtures.crawl_summary_fixture()
        |> Ecto.Changeset.change(%{completed_at: ~U[2022-08-07 19:11:40Z]})
        |> Repo.update!()

      _cs2 =
        CrawlSummariesFixtures.crawl_summary_fixture()
        |> Ecto.Changeset.change(%{completed_at: ~U[2021-08-07 19:11:40Z]})
        |> Repo.update!()

      assert "Aug 07 2022" == Crawler.data_last_updated_on()
    end
  end
end
