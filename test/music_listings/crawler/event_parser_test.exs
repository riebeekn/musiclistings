defmodule MusicListings.Crawler.EventParserTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.Payload
  alias MusicListings.Parsing.VenueParsers.HistoryParser
  alias MusicListings.PayloadsFixtures
  alias MusicListingsSchema.Venue

  describe "parse_events/3" do
    setup do
      payloads = PayloadsFixtures.load_payloads("test/data/history/single_event.html")
      venue = Repo.get_by!(Venue, name: "History")

      %{payloads: payloads, venue: venue}
    end

    test "on successful parse returns payload populated with parsed event", %{
      payloads: payloads,
      venue: venue
    } do
      [payload] =
        EventParser.parse_events(
          payloads,
          HistoryParser,
          venue,
          insert(:crawl_summary)
        )

      venue_id = venue.id

      assert %Payload{
               status: :ok,
               parsed_event: %MusicListingsSchema.Event{
                 external_id: "lucky_daye_2024_07_31",
                 title: "Lucky Daye",
                 headliner: "Lucky Daye",
                 openers: [],
                 date: ~D[2024-07-31],
                 time: ~T[20:00:00],
                 price_format: :unknown,
                 price_lo: nil,
                 price_hi: nil,
                 age_restriction: :unknown,
                 ticket_url: "https://www.ticketmaster.ca/event/10006099F25B4189",
                 venue_id: ^venue_id
               }
             } = payload
    end

    test "on failed parse returns payload populated with parse error", %{venue: venue} do
      parse_error_payloads =
        PayloadsFixtures.load_payloads("test/data/history/parse_error_event.html")

      [payload] =
        EventParser.parse_events(
          parse_error_payloads,
          HistoryParser,
          venue,
          insert(:crawl_summary)
        )

      assert :parse_error = payload.status
    end
  end
end
