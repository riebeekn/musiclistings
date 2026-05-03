defmodule MusicListingsWeb.SEOTest do
  use MusicListings.DataCase, async: true

  alias MusicListingsWeb.SEO

  describe "slugify/1" do
    test "converts a title to a lowercase dashed slug" do
      assert SEO.slugify("Fontaines D.C. Live at Phoenix!") == "fontaines-d-c-live-at-phoenix"
    end

    test "collapses runs of non-alphanumerics" do
      assert SEO.slugify("  multiple   spaces --- dashes  ") == "multiple-spaces-dashes"
    end

    test "returns a fallback for empty-ish input" do
      assert SEO.slugify("") == "event"
      assert SEO.slugify("!!!") == "event"
      assert SEO.slugify(nil) == ""
    end

    test "truncates very long titles" do
      long = String.duplicate("a", 200)
      assert long |> SEO.slugify() |> String.length() == 80
    end
  end

  describe "event_slug/1 + event_path/1" do
    test "uses the event title for the slug" do
      event = insert(:event, title: "Cool Band — Live")
      assert SEO.event_slug(event) == "cool-band-live"
      assert SEO.event_path(event) == "/events/#{event.id}/cool-band-live"
    end

    test "falls back to event-id when the title produces an empty slug" do
      event = %MusicListingsSchema.Event{id: 42, title: "!!!"}
      assert SEO.event_slug(event) == "event-42"
    end
  end

  describe "event_json_ld/1" do
    test "builds a valid MusicEvent structure" do
      venue =
        insert(:venue,
          street: "370 Queen St W",
          city: "Toronto",
          province: "ON",
          postal_code: "M5V 2A2",
          country: "Canada"
        )

      event =
        insert(:event,
          venue: venue,
          title: "Great Show",
          headliner: "Main Act",
          openers: ["Opener One"],
          date: ~D[2026-05-01],
          time: ~T[20:00:00],
          price_format: :range,
          price_lo: Decimal.new("15.00"),
          price_hi: Decimal.new("25.00"),
          ticket_url: "https://tickets.example.com/show"
        )

      json = SEO.event_json_ld(event)

      assert json["@type"] == "MusicEvent"
      assert json["name"] == "Great Show"
      assert json["url"] =~ "/events/#{event.id}/great-show"
      assert json["image"] =~ "/images/og-default.png"
      assert json["image"] == SEO.canonical_url(SEO.default_og_image())
      assert json["startDate"] =~ "2026-05-01T20:00:00"
      assert json["eventAttendanceMode"] == "https://schema.org/OfflineEventAttendanceMode"
      assert json["location"]["@type"] == "MusicVenue"
      assert json["location"]["name"] == venue.name
      assert json["location"]["address"]["streetAddress"] == "370 Queen St W"
      assert Enum.any?(json["performer"], &(&1["name"] == "Main Act"))
      assert Enum.any?(json["performer"], &(&1["name"] == "Opener One"))
      assert [offer] = json["offers"]
      assert offer["lowPrice"] == "15.00"
      assert offer["highPrice"] == "25.00"
      assert offer["priceCurrency"] == "CAD"
    end

    test "omits offers when no ticket_url is set" do
      event = insert(:event, ticket_url: nil, price_format: :fixed)
      json = SEO.event_json_ld(event)
      refute Map.has_key?(json, "offers")
    end

    test "emits price 0 for pay-what-you-can events" do
      event =
        insert(:event,
          price_format: :pwyc,
          price_lo: nil,
          price_hi: nil,
          ticket_url: "https://tickets.example.com/pwyc"
        )

      json = SEO.event_json_ld(event)

      assert [offer] = json["offers"]
      assert offer["price"] == "0"
      assert offer["priceCurrency"] == "CAD"
    end
  end

  describe "venue_json_ld/1" do
    test "returns a MusicVenue with PostalAddress" do
      venue = insert(:venue, city: "Toronto")
      json = SEO.venue_json_ld(venue)

      assert json["@type"] == "MusicVenue"
      assert json["name"] == venue.name
      assert json["address"]["@type"] == "PostalAddress"
      assert json["address"]["addressLocality"] == "Toronto"
    end
  end

  describe "encode_json_ld/1" do
    test "escapes </script> sequences" do
      encoded = SEO.encode_json_ld(%{"evil" => "</script>"})
      refute encoded =~ "</script>"
      assert encoded =~ "<\\/script>"
    end
  end
end
