defmodule MusicListings.Crawler.EventParserTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.Payload
  alias MusicListings.CrawlSummariesFixtures
  alias MusicListings.Parsing.VenueParsers.VelvetUndergroundParser
  alias MusicListings.PayloadsFixtures
  alias MusicListingsSchema.Venue

  describe "parse_events/3" do
    setup do
      payloads = PayloadsFixtures.load_payloads("test/data/velvet_underground/single_event.html")
      venue = Repo.get_by!(Venue, name: "Velvet Underground")

      %{payloads: payloads, venue: venue}
    end

    test "on successful parse returns payload populated with parsed event", %{
      payloads: payloads,
      venue: venue
    } do
      [payload] =
        EventParser.parse_events(
          payloads,
          VelvetUndergroundParser,
          venue,
          CrawlSummariesFixtures.crawl_summary_fixture()
        )

      venue_id = venue.id

      decimal_30 = Decimal.new("25.00")
      decimal_50 = Decimal.new("30.00")

      assert %Payload{
               status: :ok,
               parsed_event: %MusicListingsSchema.Event{
                 external_id: "post-3623",
                 title: "The Dangerous Summer",
                 headliner: "The Dangerous Summer",
                 openers: ["Bad Luck", "Rosecoloredworld"],
                 date: ~D[2024-07-15],
                 time: ~T[18:00:00],
                 price_format: :range,
                 price_lo: ^decimal_30,
                 price_hi: ^decimal_50,
                 age_restriction: :all_ages,
                 ticket_url:
                   "https://www.ticketweb.ca/event/the-dangerous-summer-velvet-underground-tickets/13465084?pl=embrace",
                 venue_id: ^venue_id
               }
             } = payload
    end

    test "on failed parse returns payload populated with parse error", %{venue: venue} do
      parse_error_payloads =
        PayloadsFixtures.load_payloads("test/data/velvet_underground/parse_error_event.html")

      [payload] =
        EventParser.parse_events(
          parse_error_payloads,
          VelvetUndergroundParser,
          venue,
          CrawlSummariesFixtures.crawl_summary_fixture()
        )

      assert :parse_error = payload.status
    end
  end
end
