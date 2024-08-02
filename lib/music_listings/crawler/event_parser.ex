defmodule MusicListings.Crawler.EventParser do
  @moduledoc """
  Takes in a list of payloads and parses the raw event, populating
  the Payload.parsed_event field
  """
  alias MusicListings.Crawler.Payload
  alias MusicListings.Parsing.VenueParser
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue

  @spec parse_events(
          payloads :: list(Payload),
          parser :: VenueParser,
          venue :: Venue,
          crawl_summary :: CrawlSummary
        ) ::
          list()
  def parse_events(payloads, parser, venue, crawl_summary) do
    payloads
    |> Enum.map(
      &Task.async(fn ->
        try do
          {:ok, parse_event(&1, parser, venue), &1}
        rescue
          error ->
            %CrawlError{
              crawl_summary_id: crawl_summary.id,
              venue_id: venue.id,
              type: :parse_error,
              error: Exception.format(:error, error, __STACKTRACE__),
              raw_event: inspect(&1.raw_event, limit: :infinity)
            }
            |> Repo.insert!()

            {:error, Exception.format(:error, error, __STACKTRACE__), &1}
        end
      end)
    )
    |> collect_results()
  end

  defp parse_event(payload, parser, venue) do
    performers = parser.performers(payload.raw_event)

    price_info = parser.price(payload.raw_event)

    %Event{
      external_id: parser.event_id(payload.raw_event),
      title: parser.event_title(payload.raw_event),
      headliner: performers.headliner,
      openers: performers.openers,
      date: parser.event_date(payload.raw_event),
      time: parser.event_time(payload.raw_event),
      price_format: price_info.format,
      price_lo: price_info.lo,
      price_hi: price_info.hi,
      age_restriction: parser.age_restriction(payload.raw_event),
      ticket_url: parser.ticket_url(payload.raw_event),
      details_url: parser.details_url(payload.raw_event),
      venue_id: venue.id
    }
  end

  defp collect_results(tasks, acc \\ [])
  defp collect_results([], acc), do: acc

  defp collect_results(tasks, acc) do
    receive do
      {ref, result} ->
        acc =
          case result do
            {:error, error, payload} ->
              [Payload.set_parse_error(payload, error) | acc]

            {:ok, parsed_event, payload} ->
              [Payload.set_parsed_event(payload, parsed_event) | acc]
          end

        remaining_tasks = Enum.reject(tasks, fn task -> task.ref == ref end)

        collect_results(
          remaining_tasks,
          acc
        )

      nil ->
        collect_results(tasks, acc)
    end
  end
end
