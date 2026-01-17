defmodule MusicListings.CrawlerTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary

  describe "crawl/1" do
    test "creates invalid_parser_error when parser module does not exist" do
      venue = insert(:venue, parser_module_name: "NonExistentParser")

      # Note: errors count in CrawlSummary only tracks payload-level errors (parse_error, save_error)
      # Venue-level errors like invalid_parser_error are tracked in crawl_errors table
      assert {:ok,
              %CrawlSummary{
                new: 0,
                updated: 0,
                duplicate: 0,
                errors: 0
              }} = Crawler.crawl([venue])

      assert [crawl_error] = Repo.all(CrawlError)
      assert crawl_error.type == :invalid_parser_error
      assert crawl_error.error == "Invalid parser module: NonExistentParser"
      assert crawl_error.venue_id == venue.id
    end

    test "creates no_events_error when parser returns empty events" do
      venue = insert(:venue, parser_module_name: "EmptyEventsParser")

      # Note: errors count in CrawlSummary only tracks payload-level errors (parse_error, save_error)
      # Venue-level errors like no_events_error are tracked in crawl_errors table
      assert {:ok,
              %CrawlSummary{
                new: 0,
                updated: 0,
                duplicate: 0,
                errors: 0
              }} = Crawler.crawl([venue])

      assert [crawl_error] = Repo.all(CrawlError)
      assert crawl_error.type == :no_events_error
      assert crawl_error.error == "No events found for #{venue.name}"
      assert crawl_error.venue_id == venue.id
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
