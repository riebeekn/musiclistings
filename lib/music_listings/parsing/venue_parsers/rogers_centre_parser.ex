defmodule MusicListings.Parsing.VenueParsers.RogersCentreParser do
  @moduledoc """
  Parser for extracing events from https://www.livenation.com/venue/KovZpa3Bbe/rogers-centre-events
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.LiveNationParser

  @impl true
  def source_url, do: "https://www.livenation.com/venue/KovZpa3Bbe/rogers-centre-events"

  @impl true
  defdelegate retrieve_events_fun, to: LiveNationParser

  @impl true
  def example_data_file_location, do: "test/data/rogers_centre/index.html"

  @impl true
  defdelegate events(body), to: LiveNationParser

  @impl true
  defdelegate next_page_url(body, current_url), to: LiveNationParser

  @impl true
  defdelegate event_id(event), to: LiveNationParser

  @impl true
  defdelegate ignored_event_id(event), to: LiveNationParser

  @impl true
  defdelegate event_title(event), to: LiveNationParser

  @impl true
  defdelegate performers(event), to: LiveNationParser

  @impl true
  defdelegate event_date(event), to: LiveNationParser

  @impl true
  defdelegate additional_dates(event), to: LiveNationParser

  @impl true
  defdelegate event_time(event), to: LiveNationParser

  @impl true
  defdelegate price(event), to: LiveNationParser

  @impl true
  defdelegate age_restriction(event), to: LiveNationParser

  @impl true
  defdelegate ticket_url(event), to: LiveNationParser

  @impl true
  defdelegate details_url(event), to: LiveNationParser
end
