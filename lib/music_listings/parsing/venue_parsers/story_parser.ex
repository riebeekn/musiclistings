defmodule MusicListings.Parsing.VenueParsers.StoryParser do
  @moduledoc """
  Parser for extracting events from https://www.storytoronto.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WixParser

  @api_url "https://www.storytoronto.ca/_api/wix-one-events-server/web/paginated-events/viewer?offset=0&filter=0&byEventId=false&members=true&paidPlans=false&locale=en-ca&filterType=1&sortOrder=0&limit=100&fetchBadges=true&draft=false&compId=comp-mhjkirsh"

  @impl true
  def source_url, do: "https://www.storytoronto.ca/"

  @impl true
  def retrieve_events_fun do
    fn url ->
      with {:ok, %HttpClient.Response{status: 200, body: html_body}} <- HttpClient.get(url),
           {:ok, token} <- extract_token(html_body) do
        HttpClient.get(@api_url, [{"authorization", token}])
      end
    end
  end

  defp extract_token(html_body) do
    json =
      html_body
      |> Selectors.match_one(css("script[type=\"application/json\"]#wix-warmup-data"))
      |> Selectors.data()
      |> Jason.decode!()

    token =
      json["appsWarmupData"]["140603ad-af8d-84a5-2c80-a0f60cb47351"]["widgetcomp-mhjkirsh"][
        "instance"
      ]["instance"]

    if token, do: {:ok, token}, else: {:error, :token_not_found}
  end

  @impl true
  def events(body) do
    ParseHelpers.maybe_decode!(body)["events"]
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: WixParser

  @impl true
  defdelegate event_id(event), to: WixParser

  @impl true
  defdelegate ignored_event_id(event), to: WixParser

  @impl true
  defdelegate event_title(event), to: WixParser

  @impl true
  defdelegate performers(event), to: WixParser

  @impl true
  defdelegate event_date(event), to: WixParser

  @impl true
  defdelegate additional_dates(event), to: WixParser

  @impl true
  defdelegate event_time(event), to: WixParser

  @impl true
  defdelegate age_restriction(event), to: WixParser

  @impl true
  def price(event) do
    ticketing = event["registration"]["ticketing"]

    case ticketing do
      %{"lowestTicketPrice" => %{"amount" => lo}, "highestTicketPrice" => %{"amount" => hi}} ->
        Price.new("$#{lo}-$#{hi}")

      _no_ticketing ->
        Price.unknown()
    end
  end

  @impl true
  def details_url(event) do
    "https://www.storytoronto.ca/event-details/#{event["slug"]}"
  end

  @impl true
  def ticket_url(event) do
    details_url(event)
  end
end
