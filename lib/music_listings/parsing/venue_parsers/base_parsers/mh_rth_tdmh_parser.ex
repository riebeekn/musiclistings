defmodule MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser do
  @moduledoc """
  Base parser for Massey Hall, Roy Thomson Hall and
  TD Music Hall, as they are on a single site

  mhrth.com sits behind a Cloudflare challenge keyed on bot score, which rejects
  the BEAM's TLS fingerprint and, from Render, even a real Chrome one.  So every
  request here goes through Firecrawl (`firecrawl: true`, see
  `MusicListings.HttpClient.Firecrawl`), which loads the page in a real browser
  on its own IPs.

  The listing has each event's dates but not its times or ticket links.  Those
  come from the event's details page, where the site's `<instance-list>` widget
  fills them in from the API behind it - so they're only there because Firecrawl
  hands back the page as the browser rendered it.  Requesting that API
  directly instead would need an `Accept: application/json` header, and Firecrawl
  doesn't pass headers on.

  Every request counts toward the challenge (and costs a Firecrawl credit), so
  events are parsed one at a time (`max_concurrency/0`) with a pause before
  every request, and an event an earlier crawl already stored ticket links for
  isn't looked up at all.  A lookup that fails is reported through
  `MusicListings.Parsing.LookupFailures` - which also stops it overwriting a
  ticket link or time an earlier crawl found.

  Once a request draws the challenge (a 403) the follow-up lookups stop for the
  rest of the venue's crawl, via `MusicListings.Parsing.ChallengeBreaker`: more
  requests won't get past it and only keep the bot score where it is.  The
  remaining events fall back to the listing's dates and are reported as lookup
  failures.  A listing page that gets through again resets the breaker, so one
  venue's challenge doesn't cost the next venue its lookups.

  Running out of Firecrawl credits stops the lookups the same way, but for the
  rest of the whole crawl: the credits won't come back before it ends.
  """
  import Meeseeks.CSS

  alias MusicListings.Events
  alias MusicListings.HttpClient
  alias MusicListings.HttpClient.Firecrawl.OutOfCreditsError
  alias MusicListings.Parsing.ChallengeBreaker
  alias MusicListings.Parsing.LookupFailures
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  require Logger

  # Pause before each request to the site, see the moduledoc.  Zero in test.
  # Also keeps us under Firecrawl's per-minute scrape limit (10/min on the free
  # plan): a 6s pause alone caps us at 10 requests a minute, whatever the page
  # load time.  The three venues are crawled one after another on one API key,
  # so it's the pace across all of them that counts.
  @default_request_interval_ms 6_000

  # The breaker tripped when Firecrawl says the account is out of credits
  @out_of_credits {__MODULE__, :firecrawl_out_of_credits}

  # Never more of the listing than this, however many pages it has
  @max_pages 5

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

  defp get(url) do
    :music_listings
    |> Application.get_env(:mhrth_request_interval_ms, @default_request_interval_ms)
    |> Process.sleep()

    HttpClient.get(url, [], firecrawl: true)
  end

  # For the per-event details page lookups.  Reduces the outcome to the body or
  # a short reason - the response itself carries a whole challenge page, too
  # much for a crawl report.
  defp get_body(url) do
    cond do
      ChallengeBreaker.tripped?(@out_of_credits) ->
        {:error,
         "skipped the request to #{url}: #{OutOfCreditsError.summary()} since an earlier request"}

      ChallengeBreaker.tripped?(__MODULE__) ->
        {:error, "skipped the request to #{url}, an earlier one drew the Cloudflare challenge"}

      true ->
        url
        |> get()
        |> track_challenge()
        |> case do
          {:ok, %HttpClient.Response{status: 200, body: body}} -> {:ok, body}
          {:ok, %HttpClient.Response{status: status}} -> {:error, "HTTP #{status} from #{url}"}
          {:error, reason} -> {:error, "request to #{url} failed: #{describe(reason)}"}
        end
    end
  end

  defp describe(reason) when is_exception(reason), do: Exception.message(reason)
  defp describe(reason), do: inspect(reason)

  # A 403 from mhrth.com is the Cloudflare challenge page
  defp track_challenge({:ok, %HttpClient.Response{status: 403}} = result) do
    ChallengeBreaker.trip(__MODULE__)
    result
  end

  # Credits don't come back mid-crawl, and each refused request would still wait
  # out the request interval, so stop asking for the rest of this crawl
  defp track_challenge({:error, %OutOfCreditsError{}} = result) do
    ChallengeBreaker.trip(@out_of_credits)
    result
  end

  defp track_challenge(result), do: result

  def events(body) do
    body
    |> Selectors.all_matches(css(".c-card--event"))
  end

  # The cards link to the event's details page, which is also what its
  # lookups are keyed on
  def dedupe_key(event), do: details_url(event)

  # Only the pages the listing links to: one past the last serves the last
  # page's events again, and each of those would make its own lookups.
  def next_page_url(body, current_url) do
    current_page =
      current_url
      |> URI.parse()
      |> Map.get(:query)
      |> URI.decode_query()
      |> Map.get("page")
      |> String.to_integer()

    if current_page < @max_pages and has_next_page?(body) do
      current_page_string = Integer.to_string(current_page)
      next_page_string = (current_page + 1) |> Integer.to_string()
      String.replace(current_url, current_page_string, next_page_string)
    else
      nil
    end
  end

  defp has_next_page?(body) do
    Selectors.match_one(body, css(".c-pagination__item--next a")) != nil
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
        result =
          stored_instances(event, details_path, base_url) ||
            do_fetch_instances(event, details_path, base_url)

        Process.put(cache_key, result)
        result

      cached ->
        cached
    end
  end

  # The lookups only add each date's time and ticket link.  Once an earlier
  # crawl has stored a ticket link for the listing's first and last dates, and
  # for every date in between that it stored, the request is skipped - every
  # request counts towards the challenge.  A date the listing gains, or a
  # stored date still without a link, sends the event back to the lookups.
  defp stored_instances(event, details_path, base_url) do
    {start_date, end_date} = index_date_range(event)

    stored =
      "#{base_url}#{details_path}"
      |> Events.list_events_by_details_url(start_date, end_date)
      |> Enum.uniq_by(& &1.date)

    stored_dates = Enum.map(stored, & &1.date)

    if start_date in stored_dates and end_date in stored_dates and
         Enum.all?(stored, &(&1.ticket_url not in [nil, ""])) do
      {:ok, Enum.map(stored, &{&1.date, &1.time, &1.ticket_url})}
    end
  end

  defp do_fetch_instances(event, details_path, base_url) do
    case fetch_showings(details_path, base_url) do
      {:ok, instances} -> {:ok, filter_instances(instances, event)}
      :error -> :error
    end
  end

  # Without the showings the event still has its date from the listing, but
  # neither a time nor a ticket link.
  defp fetch_showings(details_path, base_url) do
    with {:ok, detail_body} <- get_body("#{base_url}#{details_path}"),
         {:ok, showings} <- showings(detail_body) do
      {:ok, showings}
    else
      {:error, reason} ->
        message = "Couldn't look up the dates for #{details_path}: #{reason}"
        Logger.warning(message)
        LookupFailures.record([:time, :ticket_url], message)
        :error
    end
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

  @doc """
  Reads an event's showings, as `{date, time, ticket_url}` sorted by date and
  time, off its details page as a browser renders it.

  The `<instance-list>` widget renders each showing as a `.c-instance`, holding
  the date and either the showing itself or - when the page groups showings by
  date - a list of them.  A showing's time is only shown when it has an end time,
  and its ticket link only while it's on sale (not once it's sold out or
  postponed), so either can be `nil`.  Past showings aren't rendered at all.
  """
  @spec showings(String.t()) ::
          {:ok, [{Date.t(), Time.t() | nil, String.t() | nil}]} | {:error, String.t()}
  def showings(detail_body) do
    instance_list = Selectors.match_one(detail_body, css("instance-list"))

    cond do
      is_nil(instance_list) ->
        {:error, "no showings widget on the details page"}

      Selectors.match_one(instance_list, css(".loading-container")) ->
        {:error, "the showings hadn't loaded"}

      true ->
        instance_list
        |> Selectors.all_matches(css(".c-instance"))
        |> Enum.flat_map(&instance_showings/1)
        |> Enum.sort_by(fn {date, time, _ticket_url} ->
          {Date.to_gregorian_days(date), time && Time.to_iso8601(time)}
        end)
        |> case do
          [] -> {:error, "no dated showings"}
          showings -> {:ok, showings}
        end
    end
  end

  defp instance_showings(instance) do
    case showing_date(instance) do
      nil ->
        []

      date ->
        instance
        |> Selectors.all_matches(css("li"))
        |> Enum.filter(&Selectors.match_one(&1, css(".c-instance__info")))
        |> case do
          # a single showing, rather than a date's list of them
          [] -> [instance]
          grouped_showings -> grouped_showings
        end
        |> Enum.map(&{date, showing_time(&1), Selectors.url(&1, css(".c-btn--book"))})
    end
  end

  # e.g. "Saturday, October 31, 2026"
  defp showing_date(instance) do
    with date_string when is_binary(date_string) <-
           Selectors.text(instance, css(".c-instance__date")),
         [_full_match, month, day, year] <-
           Regex.run(~r/([A-Za-z]+)\s+(\d{1,2}),\s*(\d{4})/, date_string),
         {:ok, date} <- ParseHelpers.build_date_from_year_month_day_strings(year, month, day) do
      date
    else
      _no_date -> nil
    end
  end

  # "8:00 PM", or "8:00 PM - 10:30 PM" when the widget shows the end time too
  defp showing_time(showing) do
    case Selectors.match_one(showing, css(".c-instance__list-time span")) do
      nil ->
        nil

      time_span ->
        time_span
        |> Selectors.text()
        |> String.split(" - ")
        |> hd()
        |> ParseHelpers.time_from_time_string()
    end
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

  # The details page's path.  The listing links it by path, but by full URL
  # once a browser has rendered the page (as Firecrawl hands it back) - either
  # way it has to come out the same, as the stored events are matched on it.
  def details_url(event) do
    event
    |> Selectors.match_one(css(".c-card__cover-link"))
    |> Selectors.attr("href")
    |> URI.parse()
    |> Map.fetch!(:path)
  end
end
