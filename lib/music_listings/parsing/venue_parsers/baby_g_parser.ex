defmodule MusicListings.Parsing.VenueParsers.BabyGParser do
  @moduledoc """
  Parser for extracing events from http://thebabyg.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BgGarrisonParser

  @impl true
  def source_url, do: "http://thebabyg.com"

  @impl true
  def example_data_file_location, do: "test/data/baby_g/index.html"

  @impl true
  defdelegate events(body), to: BgGarrisonParser

  @impl true
  defdelegate next_page_url(body, current_url), to: BgGarrisonParser

  @impl true
  defdelegate event_id(event), to: BgGarrisonParser

  @impl true
  defdelegate ignored_event_id(event), to: BgGarrisonParser

  @impl true
  defdelegate event_title(event), to: BgGarrisonParser

  @impl true
  defdelegate performers(event), to: BgGarrisonParser

  @impl true
  defdelegate event_date(event), to: BgGarrisonParser

  @impl true
  defdelegate additional_dates(event), to: BgGarrisonParser

  @impl true
  defdelegate event_time(event), to: BgGarrisonParser

  @impl true
  defdelegate price(event), to: BgGarrisonParser

  @impl true
  defdelegate age_restriction(event), to: BgGarrisonParser

  @impl true
  defdelegate ticket_url(event), to: BgGarrisonParser

  @impl true
  defdelegate details_url(event), to: BgGarrisonParser
end
