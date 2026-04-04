defmodule MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser do
  @moduledoc """
  Base parser for Massey Hall, Roy Thomson Hall and
  TD Music Hall, as they are on a single site
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  require Logger

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

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
      {:ok, [{first_date, _first_time} | _rest]} -> first_date
      :error -> event_date(event)
    end
  end

  def additional_dates(event, base_url) do
    case fetch_instances(event, base_url) do
      {:ok, [_first | rest]} -> Enum.map(rest, fn {date, _time} -> date end)
      :error -> additional_dates(event)
    end
  end

  def event_time(event, base_url) do
    case fetch_instances(event, base_url) do
      {:ok, [{_first_date, time} | _rest]} -> time
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
    if Application.get_env(:music_listings, :env) == :test do
      :error
    else
      if has_date_range?(event) do
        fetch_instances_from_api(details_path, base_url)
      else
        :error
      end
    end
  end

  defp has_date_range?(event) do
    event
    |> event_dates()
    |> String.contains?(" - ")
  end

  defp fetch_instances_from_api(details_path, base_url) do
    with {:ok, %HttpClient.Response{status: 200, body: detail_body}} <-
           HttpClient.get("#{base_url}#{details_path}"),
         {:ok, event_id} <- extract_event_id(detail_body),
         {:ok, %HttpClient.Response{status: 200, body: api_body}} <-
           HttpClient.get("#{base_url}/api/attendable/v1/instances/?child_of=#{event_id}"),
         {:ok, instances} <- parse_instances(api_body) do
      {:ok, instances}
    else
      error ->
        Logger.warning("Failed to fetch instances for #{details_path}: #{inspect(error)}")
        :error
    end
  end

  defp extract_event_id(html_body) do
    case Regex.run(~r/instance-list[^>]*event-id="(\d+)"/, html_body) do
      [_full_match, event_id] -> {:ok, event_id}
      _no_match -> :error
    end
  end

  defp parse_instances(body) do
    json = ParseHelpers.maybe_decode!(body)

    case json do
      %{"items" => items} when is_list(items) ->
        instances =
          items
          |> Enum.map(&parse_instance_title/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.sort()

        if instances == [], do: :error, else: {:ok, instances}

      _unexpected ->
        :error
    end
  end

  defp parse_instance_title(%{"title" => title}) when is_binary(title) do
    case Regex.run(~r/^(\d{4}-\d{2}-\d{2}),\s*(\d{2}:\d{2})/, title) do
      [_full_match, date_str, time_str] ->
        with {:ok, date} <- Date.from_iso8601(date_str),
             {:ok, time} <- Time.from_iso8601("#{time_str}:00") do
          {date, time}
        else
          _error -> nil
        end

      _no_match ->
        nil
    end
  end

  defp parse_instance_title(_item), do: nil

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(_event) do
    nil
  end

  def details_url(event) do
    event
    |> Selectors.match_one(css(".c-card__cover-link"))
    |> Selectors.attr("href")
  end
end
