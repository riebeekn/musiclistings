defmodule MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser do
  @moduledoc """
  Base parser for Massey Hall, Roy Thomson Hall and
  TD Music Hall, as they are on a single site

  mhrth.com sits behind a Cloudflare challenge that rejects the BEAM's TLS
  fingerprint, so every request here is made with `browser: true`
  (see `MusicListings.HttpClient.CurlImpersonate`).

  Even then the challenge is keyed on a bot score, and each event costs two
  follow-up requests: the details page (for the event id) and the instances
  API (for each date's time and ticket link).
  Fired off eight events at a time that burst was enough to start drawing
  challenges part way through a crawl, leaving events without ticket links.  So
  events are parsed one at a time (`max_concurrency/0`) with a pause before
  every request, and a lookup that fails is reported through
  `MusicListings.Parsing.LookupFailures` - which also stops it overwriting a
  ticket link or time an earlier crawl found.

  Once a request draws the challenge (a 403) the follow-up lookups stop for the
  rest of the venue's crawl, via `MusicListings.Parsing.ChallengeBreaker`: more
  requests won't get past it and only keep the bot score where it is.  The
  remaining events fall back to the listing's dates and are reported as lookup
  failures.  A listing page that gets through again resets the breaker, so one
  venue's challenge doesn't cost the next venue its lookups.
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ChallengeBreaker
  alias MusicListings.Parsing.LookupFailures
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  require Logger

  # Pause before each request to the site, see the moduledoc.  Zero in test.
  @default_request_interval_ms 500

  # The API is a Django REST framework one, which picks its renderer from the
  # Accept header.  curl-impersonate sends Chrome's page-load Accept header,
  # which selects the HTML "browsable API" renderer - and that 500s for many
  # events.  Asking for JSON, as the site's own ticket widget does, doesn't.
  @api_headers [{"accept", "application/json"}]

  def retrieve_events_fun do
    fn url ->
      case get(url) do
        {:ok, %HttpClient.Response{status: 200}} = result ->
          ChallengeBreaker.reset(__MODULE__)
          result

        result ->
          track_challenge(result)
      end
    end
  end

  def max_concurrency, do: 1

  defp get(url, headers \\ [], opts \\ []) do
    :music_listings
    |> Application.get_env(:mhrth_request_interval_ms, @default_request_interval_ms)
    |> Process.sleep()

    HttpClient.get(url, headers, [browser: true] ++ opts)
  end

  # For the per-event follow-up lookups (details page, instances API).  Reduces
  # the outcome to the body or a short reason - the response itself carries a
  # whole challenge page, too much for a crawl report.
  #
  # A 500 from these endpoints has so far been a request the site can't serve
  # (see @api_headers), not a blip, so retrying it only adds requests - and
  # request volume is what draws the challenge.  The listing pages keep the
  # default retries: losing one loses the whole venue.
  defp get_body(url, headers \\ []) do
    if ChallengeBreaker.tripped?(__MODULE__) do
      {:error, "skipped the request to #{url}, an earlier one drew the Cloudflare challenge"}
    else
      url
      |> get(headers, no_retry_statuses: [500])
      |> track_challenge()
      |> case do
        {:ok, %HttpClient.Response{status: 200, body: body}} -> {:ok, body}
        {:ok, %HttpClient.Response{status: status}} -> {:error, "HTTP #{status} from #{url}"}
        {:error, reason} -> {:error, "request to #{url} failed: #{inspect(reason)}"}
      end
    end
  end

  # A 403 from mhrth.com is the Cloudflare challenge page
  defp track_challenge({:ok, %HttpClient.Response{status: 403}} = result) do
    ChallengeBreaker.trip(__MODULE__)
    result
  end

  defp track_challenge(result), do: result

  defp decode(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _error} -> {:error, "response was not JSON"}
    end
  end

  defp decode(body), do: {:ok, body}

  def events(body) do
    body
    |> Selectors.all_matches(css(".c-card--event"))
  end

  def next_page_url(_body, current_url) do
    current_page =
      current_url
      |> URI.parse()
      |> Map.get(:query)
      |> URI.decode_query()
      |> Map.get("page")
      |> String.to_integer()

    if current_page < 5 do
      current_page_string = Integer.to_string(current_page)
      next_page_string = (current_page + 1) |> Integer.to_string()
      String.replace(current_url, current_page_string, next_page_string)
    else
      nil
    end
  end

  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  def ignored_event_id(event), do: event_id(event)

  def event_title(event) do
    Selectors.text(event, css(".c-card__title"))
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    [first | _remaining_dates] =
      event
      |> event_dates()
      |> String.split(" - ", trim: true)

    Date.from_iso8601!(first)
  end

  def additional_dates(event) do
    event
    |> event_dates()
    |> String.split(" - ", trim: true)
    |> case do
      [_no_additional_dates] ->
        []

      [start_date_string, end_date_string] ->
        start_date = Date.from_iso8601!(start_date_string)
        end_date = Date.from_iso8601!(end_date_string)

        start_date
        |> Date.range(end_date)
        # skip the first (primary) date
        |> Enum.drop(1)
        |> Enum.to_list()
    end
  end

  defp event_dates(event) do
    event
    |> Selectors.match_one(css(".c-card__time time"))
    |> Selectors.attr("datetime")
  end

  def event_time(_event) do
    nil
  end

  def event_date(event, base_url) do
    case fetch_instances(event, base_url) do
      {:ok, [{first_date, _first_time, _booking_url} | _rest]} -> first_date
      :error -> event_date(event)
    end
  end

  def additional_dates(event, base_url) do
    case fetch_instances(event, base_url) do
      {:ok, [_first | rest]} -> Enum.map(rest, fn {date, _time, _booking_url} -> date end)
      :error -> additional_dates(event)
    end
  end

  def event_time(event, base_url) do
    case fetch_instances(event, base_url) do
      {:ok, [{_first_date, time, _booking_url} | _rest]} -> time
      :error -> nil
    end
  end

  defp fetch_instances(event, base_url) do
    details_path = details_url(event)
    cache_key = {:mh_rth_tdmh_instances, details_path}

    case Process.get(cache_key) do
      nil ->
        result = do_fetch_instances(event, details_path, base_url)
        Process.put(cache_key, result)
        result

      cached ->
        cached
    end
  end

  defp do_fetch_instances(event, details_path, base_url) do
    case fetch_instances_from_api(details_path, base_url) do
      {:ok, instances} -> {:ok, filter_instances(instances, event)}
      :error -> :error
    end
  end

  # Without the instances the event still has its date from the listing, but
  # neither a time nor a ticket link.
  defp fetch_instances_from_api(details_path, base_url) do
    with {:ok, detail_body} <- get_body("#{base_url}#{details_path}"),
         {:ok, event_id} <- extract_event_id(detail_body),
         {:ok, api_body} <- get_body(instances_url(base_url, event_id), @api_headers),
         {:ok, instances} <- parse_instances(api_body) do
      {:ok, instances}
    else
      {:error, reason} ->
        message = "Couldn't look up the dates for #{details_path}: #{reason}"
        Logger.warning(message)
        LookupFailures.record([:time, :ticket_url], message)
        :error
    end
  end

  # Mirrors the request the site's own ticket widget makes.  Without `fields`
  # the response carries no booking URL, which would cost another request per
  # date.
  defp instances_url(base_url, event_id) do
    query =
      URI.encode_query(%{
        "child_of" => event_id,
        "limit" => 1000,
        "fields" => "start_datetime,booking_url,generated_booking_url",
        "order" => "start_datetime"
      })

    "#{base_url}/api/attendable/v1/instances/?#{query}"
  end

  defp filter_instances(instances, event) do
    {start_date, end_date} = index_date_range(event)

    instances
    |> Enum.filter(fn {date, _time, _booking_url} ->
      Date.compare(date, start_date) != :lt and Date.compare(date, end_date) != :gt
    end)
    |> Enum.uniq_by(fn {date, _time, _booking_url} -> date end)
  end

  defp index_date_range(event) do
    event
    |> event_dates()
    |> String.split(" - ", trim: true)
    |> case do
      [single_date] ->
        date = Date.from_iso8601!(single_date)
        {date, date}

      [start_date_string, end_date_string] ->
        {Date.from_iso8601!(start_date_string), Date.from_iso8601!(end_date_string)}
    end
  end

  defp extract_event_id(html_body) do
    case Regex.run(~r/instance-list[^>]*event-id="(\d+)"/, html_body) do
      [_full_match, event_id] -> {:ok, event_id}
      _no_match -> {:error, "no event id on the details page"}
    end
  end

  defp parse_instances(body) do
    case decode(body) do
      {:ok, %{"items" => items}} when is_list(items) ->
        instances =
          items
          |> Enum.map(&parse_instance/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.sort_by(fn {date, time, _booking_url} -> {date, time} end)

        if instances == [], do: {:error, "no dated instances"}, else: {:ok, instances}

      {:ok, _unexpected} ->
        {:error, "unexpected instances response"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_instance(%{"title" => title} = item) when is_binary(title) do
    case Regex.run(~r/^(\d{4}-\d{2}-\d{2}),\s*(\d{2}:\d{2})/, title) do
      [_full_match, date_str, time_str] ->
        with {:ok, date} <- Date.from_iso8601(date_str),
             {:ok, time} <- Time.from_iso8601("#{time_str}:00") do
          {date, time, booking_url(item)}
        else
          _error -> nil
        end

      _no_match ->
        nil
    end
  end

  defp parse_instance(_item), do: nil

  # The site's widget falls back to the generated tickets.mhrth.com link when an
  # instance has no booking_url of its own.  Neither means no ticket link (yet).
  defp booking_url(item) do
    Enum.find_value(["booking_url", "generated_booking_url"], fn field ->
      case item[field] do
        url when is_binary(url) and url != "" -> url
        _missing -> nil
      end
    end)
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event, base_url) do
    case fetch_instances(event, base_url) do
      {:ok, [{_date, _time, booking_url} | _rest]} -> booking_url
      _error -> nil
    end
  end

  def ticket_url(event, base_url, date) do
    with {:ok, instances} <- fetch_instances(event, base_url),
         {_date, _time, booking_url} <-
           Enum.find(instances, fn {instance_date, _time, _booking_url} ->
             Date.compare(instance_date, date) == :eq
           end) do
      booking_url
    else
      _error -> nil
    end
  end

  def details_url(event) do
    event
    |> Selectors.match_one(css(".c-card__cover-link"))
    |> Selectors.attr("href")
  end
end
