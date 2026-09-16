defmodule MusicListings.Parsing.VenueParsers.HughsRoomParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HughsRoomParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/hughs_room/index.json")

    index_json = File.read!(index_file_path)

    event =
      index_json
      |> HughsRoomParser.events()
      |> List.first()

    %{index_json: index_json, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.showpass.com/api/public/events/?ends_on__gte=2024-08-01T12:00:00Z&only_parents=true&ordering=starts_on,id&page=1&page_size=50&venue__in=5705" ==
               HughsRoomParser.source_url()
    end
  end

  describe "retrieve_events_fun/0" do
    test "pulls the Showpass events feed" do
      assert {:ok, %Response{status: 200, body: body}} =
               HughsRoomParser.retrieve_events_fun().(HughsRoomParser.source_url())

      assert 49 = body |> HughsRoomParser.events() |> Enum.count()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_json: index_json} do
      events = HughsRoomParser.events(index_json)

      # 50 results, one of which is a ticket bundle hidden from the calendar
      assert 49 = Enum.count(events)
    end

    test "drops events hidden from the calendar or without a confirmed date" do
      body =
        Jason.encode!(%{
          "results" => [
            %{"slug" => "listed", "starts_on" => "2026-09-18T00:00:00Z"},
            %{
              "slug" => "hidden",
              "starts_on" => "2026-09-18T00:00:00Z",
              "show_on_calendar" => false
            },
            %{
              "slug" => "tbd",
              "starts_on" => "2026-09-18T00:00:00Z",
              "date_time_to_be_determined" => "TBD"
            },
            %{"slug" => "no-start", "starts_on" => nil}
          ]
        })

      assert ["listed"] =
               body |> HughsRoomParser.events() |> Enum.map(&HughsRoomParser.event_id/1)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url when there are more pages", %{index_json: index_json} do
      assert "https://www.showpass.com/api/public/events/?ends_on__gte=2026-09-16T00%3A00%3A00Z&only_parents=true&ordering=starts_on%2Cid&page=2&page_size=50&venue__in=5705" ==
               HughsRoomParser.next_page_url(index_json, HughsRoomParser.source_url())
    end

    test "returns nil on the last page" do
      body = Jason.encode!(%{"results" => [], "next" => nil})

      assert nil == HughsRoomParser.next_page_url(body, HughsRoomParser.source_url())
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "celebrate-the-music-of-hermeto-pascal-with-jovino-santos-neto" ==
               HughsRoomParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns event id", %{event: event} do
      assert "celebrate-the-music-of-hermeto-pascal-with-jovino-santos-neto" ==
               HughsRoomParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Celebrate the Music of Hermeto Pascoal with Jovino Santos Neto" ==
               HughsRoomParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Celebrate the Music of Hermeto Pascoal with Jovino Santos Neto",
               openers: []
             } == HughsRoomParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      # starts_on is 2026-09-18T00:00:00Z, i.e. the evening of the 17th in Toronto
      assert ~D[2026-09-17] == HughsRoomParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HughsRoomParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == HughsRoomParser.event_time(event)
    end

    test "uses the venue's local time in winter", %{index_json: index_json} do
      event = find_event(index_json, "allison-lupton")

      assert ~D[2026-11-05] == HughsRoomParser.event_date(event)
      assert ~T[20:00:00] == HughsRoomParser.event_time(event)
    end

    test "returns nil when there is no local start time" do
      assert nil == HughsRoomParser.event_time(%{"local_starts_on" => nil})
    end
  end

  describe "price/1" do
    test "returns the spread across ticket tiers", %{event: event} do
      assert %Price{format: :range, lo: Decimal.new("30.00"), hi: Decimal.new("45.00")} ==
               HughsRoomParser.price(event)
    end

    test "returns a fixed price when there is a single tier", %{index_json: index_json} do
      event = find_event(index_json, "penderecki-quartet-w-brian-dickinson")

      assert %Price{format: :fixed, lo: Decimal.new("45.00"), hi: Decimal.new("45.00")} ==
               HughsRoomParser.price(event)
    end

    test "ignores password protected tiers" do
      event = %{
        "ticket_types" => [
          %{"price" => "20.00", "is_password_protected" => false},
          %{"price" => "5.00", "is_password_protected" => true}
        ]
      }

      assert %Price{format: :fixed, lo: Decimal.new("20.00"), hi: Decimal.new("20.00")} ==
               HughsRoomParser.price(event)
    end

    test "returns unknown when there are no ticket types" do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               HughsRoomParser.price(%{"ticket_types" => []})
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HughsRoomParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.showpass.com/celebrate-the-music-of-hermeto-pascal-with-jovino-santos-neto/" ==
               HughsRoomParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.showpass.com/celebrate-the-music-of-hermeto-pascal-with-jovino-santos-neto/" ==
               HughsRoomParser.details_url(event)
    end
  end

  defp find_event(index_json, slug) do
    index_json
    |> HughsRoomParser.events()
    |> Enum.find(&(HughsRoomParser.event_id(&1) == slug))
  end
end
