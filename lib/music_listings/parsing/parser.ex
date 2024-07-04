defmodule MusicListings.Parsing.Parser do
  alias MusicListings.Parsing.Performers

  @callback source_url() :: String.t()
  @callback venue_name() :: String.t()
  @callback event_selector(String.t()) :: [Meeseeks.Result.t()] | {:error, Meeseeks.Error.t()}
  @callback next_page_url(String.t()) :: String.t()
  @callback event_id(String.t()) :: String.t()
  @callback event_title(String.t()) :: String.t()
  @callback performers(String.t()) :: Performers.t()
  @callback event_date(String.t()) :: Date.t()
  @callback event_time(String.t()) :: Time.t()
  @callback price(String.t()) :: Price.t()
  @callback age_restriction(String.t()) :: [:all_ages | :nineteen_plus | :tbd]
  @callback ticket_url(String.t()) :: String.t()
end
