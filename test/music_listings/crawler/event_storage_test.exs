defmodule MusicListings.Crawler.EventStorageTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.EventStorage
  alias MusicListings.Crawler.Payload
  alias MusicListings.CrawlSummariesFixtures
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.Event

  describe "save_events/1" do
    setup do
      payloads = [
        %Payload{
          status: :ok,
          parsed_event: %Event{
            external_id: "post-17036",
            title: "Northlane",
            headliner: "Northlane",
            openers: ["Invent Animate", "Thornhill", "Windwaker"],
            date: ~D[2024-07-05],
            time: ~T[18:00:00],
            price_format: :range,
            price_lo: Decimal.new("30.00"),
            price_hi: Decimal.new("50.00"),
            age_restriction: :all_ages,
            ticket_url: "https://www.ticketmaster.ca/event/1000603D7B880DBA",
            venue_id: 2
          }
        }
      ]

      crawl_summary = CrawlSummariesFixtures.crawl_summary_fixture()

      %{payloads: payloads, crawl_summary: crawl_summary}
    end

    test "saves the event and updates the operation and persisted event on the payload", %{
      payloads: payloads,
      crawl_summary: crawl_summary
    } do
      [payload] =
        EventStorage.save_events(payloads, crawl_summary)

      assert :created == payload.operation

      decimal_30 = Decimal.new("30.00")
      decimal_50 = Decimal.new("50.00")

      assert %Event{
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
               ticket_url: "https://www.ticketmaster.ca/event/1000603D7B880DBA",
               venue_id: 2
             } = payload.persisted_event
    end

    test "performs no operation on a duplicate event", %{
      payloads: payloads,
      crawl_summary: crawl_summary
    } do
      EventStorage.save_events(payloads, crawl_summary)
      [payload] = EventStorage.save_events(payloads, crawl_summary)

      assert :noop == payload.operation
    end

    test "returns save_error and inserts a crawl error on invalid parsed event", %{
      payloads: payloads,
      crawl_summary: crawl_summary
    } do
      # update the parsed event to have a blank title
      payloads =
        Enum.map(payloads, fn
          %Payload{parsed_event: %Event{} = event} = payload ->
            %{payload | parsed_event: %{event | title: ""}}
        end)

      [payload] = EventStorage.save_events(payloads, crawl_summary)

      assert :noop == payload.operation
      assert :save_error = payload.status

      assert [crawl_error] = Repo.all(CrawlError)
      assert crawl_error.type == :save_error
      assert crawl_error.error =~ "not_null_violation"
    end

    test "updates an existing event that has changed", %{
      payloads: payloads,
      crawl_summary: crawl_summary
    } do
      EventStorage.save_events(payloads, crawl_summary)

      Event
      |> last()
      |> Repo.one()
      |> Ecto.Changeset.change(%{title: "Some title which we need to update"})
      |> Repo.update!()

      [payload] = EventStorage.save_events(payloads, crawl_summary)
      assert :updated == payload.operation
    end

    test "on an invalid update returns save_error and inserts a crawl error", %{
      payloads: payloads,
      crawl_summary: crawl_summary
    } do
      EventStorage.save_events(payloads, crawl_summary)

      # update the parsed event to have a blank title
      payloads =
        Enum.map(payloads, fn
          %Payload{parsed_event: %Event{} = event} = payload ->
            %{payload | parsed_event: %{event | title: ""}}
        end)

      [payload] = EventStorage.save_events(payloads, crawl_summary)

      assert :noop == payload.operation
      assert :save_error = payload.status

      assert [crawl_error] = Repo.all(CrawlError)
      assert crawl_error.type == :save_error
      assert crawl_error.error =~ "not_null_violation"
    end

    test "does nothing where payload status is not :ok", %{crawl_summary: crawl_summary} do
      payload = %Payload{status: :parse_error}
      assert [payload] == EventStorage.save_events([payload], crawl_summary)
    end
  end
end
