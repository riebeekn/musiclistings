defmodule MusicListings.Crawler do
  alias MusicListings.Repo
  alias MusicListings.Spiders.VelvetUnderground
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias Req.Response

  require Logger

  def crawl_all do
    [VelvetUnderground]
    |> Enum.each(&crawl/1)
  end

  # Crawler.crawl(HorseshoeTavern) |> List.last()
  def crawl(spider) do
    venue = Repo.get_by!(Venue, name: spider.venue_name())

    spider
    |> download_events(spider.url())
    |> parse_events(spider, venue)
    |> maybe_insert_events()
  end

  def download_events(spider, url, events \\ []) do
    url
    |> Req.get()
    |> case do
      {:ok, %Response{status: 200, body: body}} ->
        events_from_current_body = spider.event_selector(body)

        next_page_url_result = spider.next_page_selector(body)

        if next_page_url_result do
          next_page_url = next_page_url_result |> Meeseeks.Result.attr("href")
          download_events(spider, next_page_url, events ++ events_from_current_body)
        else
          events ++ events_from_current_body
        end

      {:ok, %Response{status: status}} ->
        Logger.info("Failed to get data from #{url}, status code: #{status}")

      {:error, error} ->
        Logger.error("Error occured getting #{url}, #{inspect(error)}")
    end
  end

  # for testing:
  # events = [index |> Meeseeks.all(css(".event-block")) |> List.last]
  def parse_events(events, spider, venue) do
    events
    |> Enum.map(fn event ->
      [headliner | openers] = spider.artists_selector(event)

      %Event{
        external_id: spider.event_id_selector(event),
        title: spider.event_title_selector(event),
        headliner: headliner,
        openers: openers,
        date: spider.date_selector(event),
        time: spider.time_selector(event),
        price: spider.price_selector(event),
        age_restriction: spider.age_selector(event),
        ticket_url: spider.ticket_url_selector(event),
        venue_id: venue.id
      }
    end)
  end

  def maybe_insert_events(events) do
    events
    |> Enum.each(fn event ->
      event
      |> Repo.insert(
        on_conflict: [
          set: [
            title: event.title,
            headliner: event.headliner,
            openers: event.openers,
            date: event.date,
            time: event.time,
            price: event.price,
            age_restriction: event.age_restriction,
            ticket_url: event.ticket_url,
            updated_at: DateTime.utc_now()
          ]
        ],
        conflict_target: [:external_id, :venue_id]
      )
    end)
  end
end
