defmodule MusicListings.Emails.LatestCrawlResultsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Emails.LatestCrawlResults
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.VenueCrawlSummary
  alias MusicListingsUtilities.DateHelpers

  # The crawl summary row is written when the crawl starts, so events inserted
  # after it are the ones that crawl created. Back-date it so events inserted by
  # these tests fall inside the window. Anchor to DateHelpers.now/0, not the wall
  # clock - the schema autogenerates timestamps from it and it is frozen in test.
  defp crawl_started_at, do: DateHelpers.now() |> DateTime.add(-60, :second)

  defp crawl_summary(crawl_errors) do
    venue_crawl_summaries =
      crawl_errors
      |> Enum.map(& &1.venue)
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(fn venue ->
        %VenueCrawlSummary{
          venue: venue,
          venue_id: venue.id,
          new: 0,
          updated: 0,
          duplicate: 0,
          ignored: 0,
          errors: 0
        }
      end)

    %CrawlSummary{
      id: 1,
      new: 0,
      updated: 0,
      duplicate: 0,
      ignored: 0,
      errors: Enum.count(crawl_errors),
      inserted_at: crawl_started_at(),
      crawl_errors: crawl_errors,
      venue_crawl_summaries: venue_crawl_summaries
    }
  end

  defp no_events_error(venue) do
    %CrawlError{
      id: venue.id,
      venue: venue,
      venue_id: venue.id,
      type: :no_events_error,
      error: "No events found for #{venue.name}"
    }
  end

  defp parse_error(venue) do
    %CrawlError{
      id: 2,
      venue: venue,
      venue_id: venue.id,
      type: :parse_error,
      error: "** (FunctionClauseError) no function clause matching",
      raw_event: "<article id=\"post-8043\">raw event markup</article>"
    }
  end

  describe "new_email/1 - no events found" do
    test "hands over the local crawl command, keyed by parser module name" do
      venue = insert(:venue, parser_module_name: "BlockedVenueParser")

      email = [no_events_error(venue)] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "Crawl locally"
      assert email.html_body =~ "bin/crawl-venue.sh BlockedVenueParser"
      refute email.html_body =~ "Raw event"
    end

    test "rolls every empty venue into a single command, sorted by venue name" do
      zulu = insert(:venue, name: "Zulu Test Hall", parser_module_name: "ZuluParser")
      alpha = insert(:venue, name: "Alpha Test Hall", parser_module_name: "AlphaParser")

      email =
        [no_events_error(zulu), no_events_error(alpha)]
        |> crawl_summary()
        |> LatestCrawlResults.new_email()

      assert email.html_body =~ "bin/crawl-venue.sh AlphaParser ZuluParser"
      # one command, not one per venue
      assert email.html_body |> String.split("bin/crawl-venue.sh") |> length() == 2
    end

    test "omits the section when no venue came up empty" do
      venue = insert(:venue)

      email = [parse_error(venue)] |> crawl_summary() |> LatestCrawlResults.new_email()

      refute email.html_body =~ "Crawl locally"
    end
  end

  describe "new_email/1 - other error types" do
    test "renders the raw event and not a crawl command" do
      venue = insert(:venue, parser_module_name: "SomeVenueParser")

      email = [parse_error(venue)] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "Raw event"
      assert email.html_body =~ "raw event markup"
      refute email.html_body =~ "bin/crawl-venue.sh"
      refute email.html_body =~ "Crawl locally"
    end
  end

  describe "new_email/1 - new events" do
    test "lists the events added by the crawl, sorted by venue" do
      zulu = insert(:venue, name: "Zulu Test Hall")
      alpha = insert(:venue, name: "Alpha Test Hall")

      insert(:event, venue: zulu, title: "Sunset Rubdown", date: ~D[2026-08-14])
      insert(:event, venue: alpha, title: "Badge Epoque Ensemble", date: ~D[2026-08-21])

      email = [] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "New events (2)"
      assert email.html_body =~ "Sunset Rubdown"
      assert email.html_body =~ "Badge Epoque Ensemble"
      assert email.html_body =~ DateHelpers.format_date(~D[2026-08-14])

      # sorted by venue name, so Alpha Test Hall comes before Zulu Test Hall
      {alpha_at, _length} = :binary.match(email.html_body, "Badge Epoque Ensemble")
      {zulu_at, _length} = :binary.match(email.html_body, "Sunset Rubdown")
      assert alpha_at < zulu_at
    end

    test "omits events that predate the crawl" do
      venue = insert(:venue)

      old_event =
        insert(:event,
          venue: venue,
          title: "Already Known Show",
          inserted_at: DateHelpers.now() |> DateTime.add(-1, :day)
        )

      insert(:event, venue: venue, title: "Brand New Show")

      email = [] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "New events (1)"
      assert email.html_body =~ "Brand New Show"
      refute email.html_body =~ old_event.title
    end

    test "omits the section entirely when nothing was added" do
      email = [] |> crawl_summary() |> LatestCrawlResults.new_email()

      refute email.html_body =~ "New events"
    end
  end
end
