defmodule MusicListings.Crawler do
  @moduledoc """
  Crawler for retrieving events
  """
  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias Req.Response

  require Logger

  @doc """
  Crawler.crawl([VelvetUndergroundParser], no_www: true)
  """
  def crawl(parsers, opts \\ []) do
    get_events_from_www? = !Keyword.get(opts, :no_www, false)

    Enum.each(parsers, fn parser ->
      venue = Repo.get_by!(Venue, name: parser.venue_name())

      parser
      |> retrieve_events(parser.source_url(), get_events_from_www?)
      |> parse_events(parser, venue)
      |> upsert_events()
    end)
  end

  defp retrieve_events(parser, url, get_events_from_www?, events \\ [])

  defp retrieve_events(parser, url, true, events) do
    url
    |> Req.get()
    |> case do
      {:ok, %Response{status: 200, body: body}} ->
        events_from_current_body = parser.event_selector(body)

        next_page_url = parser.next_page_url(body)

        if next_page_url do
          retrieve_events(parser, next_page_url, true, events ++ events_from_current_body)
        else
          events ++ events_from_current_body
        end

      {:ok, %Response{status: status}} ->
        Logger.info("Failed to get data from #{url}, status code: #{status}")

      {:error, error} ->
        Logger.error("Error occured getting #{url}, #{inspect(error)}")
    end
  end

  defp retrieve_events(parser, _url, false, _events) do
    local_venue_file =
      parser.venue_name()
      |> String.replace(" ", "")
      |> to_snake_case()

    "#{File.cwd!()}/test/data/#{local_venue_file}/index.html"
    |> Path.expand()
    |> File.read!()
    |> parser.event_selector()
  end

  defp to_snake_case(string) do
    string
    |> String.replace(~r/(?=[A-Z])/, "_")
    |> String.downcase()
    |> String.trim_leading("_")
  end

  defp parse_events(events, parser, venue) do
    Enum.map(events, &parse_event(&1, parser, venue))
  end

  defp parse_event(event, parser, venue) do
    performers = parser.performers(event)

    price_info = parser.price(event)

    %Event{
      external_id: parser.event_id(event),
      title: parser.event_title(event),
      headliner: performers.headliner,
      openers: performers.openers,
      date: parser.event_date(event),
      time: parser.event_time(event),
      price_format: price_info.format,
      price_lo: price_info.lo,
      price_hi: price_info.hi,
      age_restriction: parser.age_restriction(event),
      source_url: parser.source_url(),
      ticket_url: parser.ticket_url(event),
      venue_id: venue.id
    }
  end

  defp upsert_events(events) do
    Enum.each(events, fn event ->
      Repo.insert(event,
        on_conflict: [
          set: [
            title: event.title,
            headliner: event.headliner,
            openers: event.openers,
            date: event.date,
            time: event.time,
            price_format: event.price_format,
            price_lo: event.price_lo,
            price_hi: event.price_hi,
            age_restriction: event.age_restriction,
            source_url: event.source_url,
            ticket_url: event.ticket_url,
            # problem with this is it always is updated... even on
            # no changes... so maybe instead use explict get / insert / update
            updated_at: DateTime.utc_now()
          ]
        ],
        conflict_target: [:external_id, :venue_id]
      )
    end)
  end
end
