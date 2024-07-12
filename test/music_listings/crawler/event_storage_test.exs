defmodule MusicListings.Crawler.EventStorageTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.EventStorage
  alias MusicListings.Crawler.Payload
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
            source_url: "https://thedanforth.com/",
            ticket_url: "https://www.ticketmaster.ca/event/1000603D7B880DBA",
            venue_id: 2
          }
        }
      ]

      %{payloads: payloads}
    end

    test "saves the event and updates the operation and persisted event on the payload", %{
      payloads: payloads
    } do
      [payload] = EventStorage.save_events(payloads)

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
               source_url: "https://thedanforth.com/",
               ticket_url: "https://www.ticketmaster.ca/event/1000603D7B880DBA",
               venue_id: 2
             } = payload.persisted_event
    end

    test "performs no operation on a duplicate event", %{payloads: payloads} do
      EventStorage.save_events(payloads)
      [payload] = EventStorage.save_events(payloads)

      assert :noop == payload.operation
    end

    test "updates and existing event that has changed", %{payloads: payloads} do
      EventStorage.save_events(payloads)

      Event
      |> last()
      |> Repo.one()
      |> Ecto.Changeset.change(%{title: "Some title which we need to update"})
      |> Repo.update!()

      [payload] = EventStorage.save_events(payloads)
      assert :updated == payload.operation
    end

    test "does nothing where payload status is not :ok" do
      payload = %Payload{status: :parse_error}
      assert [payload] == EventStorage.save_events([payload])
    end
  end
end
