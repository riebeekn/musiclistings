defmodule MusicListings.Crawler.EventParserTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.Payload
  alias MusicListings.CrawlSummariesFixtures
  alias MusicListings.Parsing.DanforthMusicHallParser
  alias MusicListings.PayloadsFixtures
  alias MusicListingsSchema.Venue

  describe "parse_events/3" do
    setup do
      payloads = PayloadsFixtures.load_payloads("test/data/danforth_music_hall/single_event.html")
      venue = Repo.get_by!(Venue, name: "The Danforth Music Hall")

      %{payloads: payloads, venue: venue}
    end

    test "on successful parse returns payload populated with parsed event", %{
      payloads: payloads,
      venue: venue
    } do
      [payload] =
        EventParser.parse_events(
          payloads,
          DanforthMusicHallParser,
          venue,
          CrawlSummariesFixtures.crawl_summary_fixture()
        )

      venue_id = venue.id

      decimal_30 = Decimal.new("30.00")
      decimal_50 = Decimal.new("50.00")

      assert %Payload{
               status: :ok,
               parsed_event: %MusicListingsSchema.Event{
                 external_id: "post-17036",
                 title: "Northlane",
                 headliner: "Northlane",
                 openers: ["Invent Animate", "Thornhill", "Windwaker"],
                 date: ~D[2024-07-05],
                 time: ~T[18:00:00],
                 price_format: :range,
                 price_lo: ^decimal_30,
                 price_hi: ^decimal_50,
                 age_restriction: :all_ages,
                 source_url: "https://thedanforth.com",
                 ticket_url: "https://www.ticketmaster.ca/event/1000603D7B880DBA",
                 venue_id: ^venue_id
               }
             } = payload
    end

    test "on failed parse returns payload populated with parse error", %{venue: venue} do
      parse_error_payloads =
        PayloadsFixtures.load_payloads("test/data/danforth_music_hall/parse_error_event.html")

      [payload] =
        EventParser.parse_events(
          parse_error_payloads,
          DanforthMusicHallParser,
          venue,
          CrawlSummariesFixtures.crawl_summary_fixture()
        )

      assert :parse_error = payload.status
    end
  end
end
