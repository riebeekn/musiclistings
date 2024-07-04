defmodule MusicListings.Crawler do
  alias MusicListings.Parsing.DanforthMusicHall
  # alias MusicListings.Parsing.VelvetUnderground
  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias Req.Response

  require Logger

  def crawl_all do
    # , VelvetUnderground]
    [DanforthMusicHall]
    |> Enum.each(&crawl/1)
  end

  def crawl(spider) do
    venue = Repo.get_by!(Venue, name: spider.venue_name())

    spider
    |> download_events(spider.source_url())
    |> parse_events(spider, venue)
    |> upsert_events()
  end

  def download_events(spider, url, events \\ []) do
    url
    |> Req.get()
    |> case do
      {:ok, %Response{status: 200, body: body}} ->
        events_from_current_body = spider.event_selector(body)

        next_page_url_result = spider.next_page_url(body)

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

  # for testing: ... maybe should move these comments into the parsers?
  # index_file_path = Path.expand("#{File.cwd!()}/test/data/velvet_underground/index.html")
  # index_file_path = Path.expand("#{File.cwd!()}/test/data/danforth_music_hall/index.html")
  # index = File.read!(index_file_path)
  # FOR A SINGLE EVENT FOR INITIAL TESTING
  # events = [index |> Meeseeks.all(css(".event-block")) |> List.last]
  # FOR ALL EVENTS
  # events = index |> Meeseeks.all(css(".event-block"))
  # venue = Repo.get_by!(Venue, name: "Danforth Music Hall")
  # venue = Repo.get_by!(Venue, name: "Velvet Underground")
  # Crawler.parse_events(events, DanforthMusicHallParser, venue)
  # Crawler.parse_events(events, VelvetUndergroundParser, venue)
  def parse_events(events, spider, venue) do
    events
    |> Enum.map(fn event ->
      performers = spider.performers(event)

      price_info = spider.price(event)

      %Event{
        external_id: spider.event_id(event),
        title: spider.event_title(event),
        headliner: performers.headliner,
        openers: performers.openers,
        date: spider.event_date(event),
        time: spider.event_time(event),
        price_format: price_info.format,
        price_lo: price_info.lo,
        price_hi: price_info.hi,
        age_restriction: spider.age_restriction(event),
        source_url: spider.source_url(),
        ticket_url: spider.ticket_url(event),
        venue_id: venue.id
      }
    end)
  end

  def upsert_events(events) do
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
