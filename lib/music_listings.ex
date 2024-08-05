defmodule MusicListings do
  @moduledoc """
  Main API for the application
  """
  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.IgnoredEvent
  alias MusicListingsUtilities.DateHelpers

  require Logger

  @spec ignore_crawl_error(pos_integer()) :: IgnoredEvent
  def ignore_crawl_error(crawl_error_id) do
    crawl_error =
      CrawlError
      |> Repo.get!(crawl_error_id)
      |> Repo.preload(:venue)

    parser =
      String.to_existing_atom(
        "Elixir.MusicListings.Parsing.VenueParsers.#{crawl_error.venue.parser_module_name}"
      )

    ignored_event_id =
      crawl_error.raw_event
      |> parser.events()
      |> Enum.at(0)
      |> parser.ignored_event_id()

    %IgnoredEvent{
      ignored_event_id: ignored_event_id,
      venue_id: crawl_error.venue_id
    }
    |> Repo.insert!()
  rescue
    error ->
      Logger.error("Failed to insert ignored event record.")
      Logger.error(error)
  end

  @type list_events_opts ::
          {:page, pos_integer()}
          | {:page_size, pos_integer()}
          | []
  @spec list_events(list_events_opts()) :: any()
  def list_events(opts \\ []) do
    pagination_values = page_and_page_size_from_opts(opts)

    today = DateHelpers.today()

    Event
    |> where([event], event.date >= ^today)
    |> order_by(:date)
    |> preload(:venue)
    |> Repo.paginate(page: pagination_values.page, page_size: pagination_values.page_size)
    |> Enum.group_by(& &1.date)
    |> Enum.map(fn {date, events} ->
      sorted_events = Enum.sort_by(events, & &1.title)
      {date, sorted_events}
    end)
    |> Enum.sort(fn {date1, _}, {date2, _} ->
      Date.compare(date1, date2) != :gt
    end)
  end

  @default_page 1
  @default_page_size 100

  defp page_and_page_size_from_opts(opts) do
    page = opts |> Keyword.get(:page, @default_page) |> max(1)
    page_size = opts |> Keyword.get(:page_size, @default_page_size) |> min(@default_page_size)

    %{
      page: page,
      page_size: page_size
    }
  end

  @spec data_last_updated_on :: String.t()
  def data_last_updated_on do
    CrawlSummary
    |> order_by([crawl_summary], desc: crawl_summary.updated_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil ->
        "No data"

      last_summary ->
        last_summary.updated_at
        |> DateHelpers.to_eastern_datetime()
        |> DateHelpers.format_datetime()
    end
  end
end
