defmodule MusicListingsWeb.SEO do
  @moduledoc """
  Builds SEO artifacts — JSON-LD structured data, canonical URLs, slugs,
  and meta descriptions — for pages on the site.
  """

  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias MusicListingsWeb.Endpoint

  @site_name "Toronto Music Listings"
  @default_description "Discover Toronto's vibrant music scene with daily updated event listings. From local bands to international acts, find live shows, concerts, and music festivals happening in and around Toronto."
  @default_og_image "/images/og-default.png"

  @spec site_name() :: String.t()
  def site_name, do: @site_name

  @spec default_description() :: String.t()
  def default_description, do: @default_description

  @spec default_og_image() :: String.t()
  def default_og_image, do: @default_og_image

  @spec canonical_url(String.t()) :: String.t()
  def canonical_url(path) when is_binary(path) do
    base = Endpoint.url() |> String.trim_trailing("/")
    base <> path
  end

  @spec event_path(Event.t()) :: String.t()
  def event_path(%Event{id: id} = event) do
    "/events/#{id}/#{event_slug(event)}"
  end

  @spec event_url(Event.t()) :: String.t()
  def event_url(%Event{} = event), do: canonical_url(event_path(event))

  @spec event_slug(Event.t()) :: String.t()
  def event_slug(%Event{id: id, title: title}) do
    case slugify(title) do
      "event" -> "event-#{id}"
      slug -> slug
    end
  end

  @spec slugify(String.t() | nil) :: String.t()
  def slugify(nil), do: ""

  def slugify(string) when is_binary(string) do
    string
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> String.slice(0, 80)
    |> case do
      "" -> "event"
      slug -> slug
    end
  end

  @spec event_meta_description(Event.t()) :: String.t()
  def event_meta_description(%Event{} = event) do
    date_part = date_phrase(event.date)
    openers_part = openers_phrase(event.openers)
    price_part = price_phrase(event)

    "#{event.title} live at #{event.venue.name} in Toronto on #{date_part}#{openers_part}. #{price_part}Full details and tickets on Toronto Music Listings."
    |> String.slice(0, 300)
  end

  defp date_phrase(%Date{} = date), do: Calendar.strftime(date, "%A, %B %-d, %Y")

  defp openers_phrase([]), do: ""

  defp openers_phrase(openers) when is_list(openers) do
    " with " <> Enum.join(openers, ", ")
  end

  defp price_phrase(%Event{price_format: :free}), do: "Free show. "
  defp price_phrase(%Event{price_format: :pwyc}), do: "Pay what you can. "

  defp price_phrase(%Event{price_format: :fixed, price_lo: %Decimal{} = lo}),
    do: "Tickets $#{lo}. "

  defp price_phrase(%Event{
         price_format: :range,
         price_lo: %Decimal{} = lo,
         price_hi: %Decimal{} = hi
       }),
       do: "Tickets $#{lo}–$#{hi}. "

  defp price_phrase(%Event{price_format: :variable, price_lo: %Decimal{} = lo}),
    do: "Tickets from $#{lo}. "

  defp price_phrase(_event), do: ""

  @spec organization_json_ld() :: map()
  def organization_json_ld do
    %{
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => @site_name,
      "url" => Endpoint.url(),
      "description" => @default_description
    }
  end

  @spec website_json_ld() :: map()
  def website_json_ld do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => @site_name,
      "url" => Endpoint.url()
    }
  end

  @spec venue_json_ld(Venue.t()) :: map()
  def venue_json_ld(%Venue{} = venue) do
    %{
      "@context" => "https://schema.org",
      "@type" => "MusicVenue",
      "name" => venue.name,
      "url" => canonical_url("/events/venue/#{venue.id}"),
      "sameAs" => venue.website,
      "address" => postal_address(venue)
    }
    |> compact()
  end

  @spec event_json_ld(Event.t()) :: map()
  def event_json_ld(%Event{} = event) do
    venue = event.venue

    %{
      "@context" => "https://schema.org",
      "@type" => "MusicEvent",
      "name" => event.title || event.headliner,
      "url" => event_url(event),
      "startDate" => iso8601_start(event.date, event.time),
      "eventAttendanceMode" => "https://schema.org/OfflineEventAttendanceMode",
      "eventStatus" => "https://schema.org/EventScheduled",
      "description" => event_meta_description(event),
      "location" => location_json(venue),
      "performer" => performers(event),
      "offers" => offers(event),
      "typicalAgeRange" => age_range(event.age_restriction),
      "organizer" => %{
        "@type" => "Organization",
        "name" => @site_name,
        "url" => Endpoint.url()
      }
    }
    |> compact()
  end

  @spec event_list_json_ld([%{id: any(), url: String.t(), name: String.t()}]) :: map()
  def event_list_json_ld(items) when is_list(items) do
    %{
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "itemListElement" =>
        items
        |> Enum.with_index(1)
        |> Enum.map(fn {%{url: url, name: name}, position} ->
          %{
            "@type" => "ListItem",
            "position" => position,
            "url" => url,
            "name" => name
          }
        end)
    }
  end

  @spec events_to_list_items([Event.t()]) :: [%{url: String.t(), name: String.t()}]
  def events_to_list_items(events) when is_list(events) do
    Enum.map(events, fn %Event{} = event ->
      %{url: event_url(event), name: event.title}
    end)
  end

  @doc """
  Builds JSON-LD list items from the grouped events structure returned by
  `MusicListings.list_events/1` (`[{date, [%EventInfo{}]}]`).
  Each entry links to the first showtime's per-event URL.
  """
  @spec grouped_events_to_list_items([{Date.t(), [struct()]}]) :: [
          %{url: String.t(), name: String.t()}
        ]
  def grouped_events_to_list_items(grouped_events) when is_list(grouped_events) do
    grouped_events
    |> Enum.flat_map(fn {_date, event_infos} -> event_infos end)
    |> Enum.map(fn info ->
      first_show = List.first(info.showtimes)
      slug = slugify(info.title)
      path = "/events/#{first_show.event_id}/#{slug}"
      %{url: canonical_url(path), name: info.title}
    end)
  end

  @spec encode_json_ld(map() | [map()]) :: String.t()
  def encode_json_ld(payload) do
    payload
    |> Jason.encode!()
    |> String.replace("</", "<\\/")
  end

  defp postal_address(%Venue{} = venue) do
    %{
      "@type" => "PostalAddress",
      "streetAddress" => venue.street,
      "addressLocality" => venue.city,
      "addressRegion" => venue.province,
      "postalCode" => venue.postal_code,
      "addressCountry" => venue.country
    }
    |> compact()
  end

  defp location_json(nil), do: nil

  defp location_json(%Venue{} = venue) do
    %{
      "@type" => "MusicVenue",
      "name" => venue.name,
      "url" => canonical_url("/events/venue/#{venue.id}"),
      "address" => postal_address(venue)
    }
    |> compact()
  end

  defp iso8601_start(%Date{} = date, %Time{} = time) do
    case DateTime.new(date, time, "America/Toronto") do
      {:ok, datetime} -> DateTime.to_iso8601(datetime)
      {:ambiguous, datetime, _later} -> DateTime.to_iso8601(datetime)
      {:gap, _before, just_after} -> DateTime.to_iso8601(just_after)
      _error -> Date.to_iso8601(date)
    end
  end

  defp iso8601_start(%Date{} = date, nil), do: Date.to_iso8601(date)

  defp performers(%Event{} = event) do
    headliner =
      if event.headliner != "",
        do: [%{"@type" => "MusicGroup", "name" => event.headliner}],
        else: []

    openers =
      event.openers
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&%{"@type" => "MusicGroup", "name" => &1})

    case headliner ++ openers do
      [] -> nil
      list -> list
    end
  end

  defp offers(%Event{} = event) do
    if is_binary(event.ticket_url) and event.ticket_url != "" do
      offer =
        %{
          "@type" => "Offer",
          "url" => event.ticket_url,
          "availability" => "https://schema.org/InStock",
          "priceCurrency" => "CAD"
        }
        |> Map.merge(price_fields(event))

      [compact(offer)]
    end
  end

  defp price_fields(%Event{price_format: :free}), do: %{"price" => "0"}

  defp price_fields(%Event{price_format: :fixed, price_lo: %Decimal{} = lo}),
    do: %{"price" => Decimal.to_string(lo)}

  defp price_fields(%Event{
         price_format: :range,
         price_lo: %Decimal{} = lo,
         price_hi: %Decimal{} = hi
       }),
       do: %{"lowPrice" => Decimal.to_string(lo), "highPrice" => Decimal.to_string(hi)}

  defp price_fields(%Event{price_format: :variable, price_lo: %Decimal{} = lo}),
    do: %{"lowPrice" => Decimal.to_string(lo)}

  defp price_fields(_event), do: %{}

  defp age_range(:all_ages), do: "All Ages"
  defp age_range(:eighteen_plus), do: "18+"
  defp age_range(:nineteen_plus), do: "19+"
  defp age_range(_unknown), do: nil

  defp compact(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> v in [nil, "", []] end)
    |> Map.new()
  end
end
