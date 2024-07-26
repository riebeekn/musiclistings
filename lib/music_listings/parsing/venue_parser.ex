defmodule MusicListings.Parsing.VenueParser do
  @moduledoc """
  Module that defines the behaviour for a Parser
  """
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @callback source_url() :: String.t()
  @callback venue_name() :: String.t()
  @callback example_data_file_location() :: String.t()
  @callback event_selector(String.t()) :: [Meeseeks.Result.t()] | {:error, Meeseeks.Error.t()}
  @callback next_page_url(String.t()) :: String.t() | nil
  @callback event_id(Meeseeks.Result.t()) :: String.t()
  @callback event_title(Meeseeks.Result.t()) :: String.t()
  @callback performers(Meeseeks.Result.t()) :: Performers.t()
  @callback event_date(Meeseeks.Result.t()) :: Date.t()
  @callback event_time(Meeseeks.Result.t()) :: Time.t() | nil
  @callback price(Meeseeks.Result.t()) :: Price.t()
  @callback age_restriction(Meeseeks.Result.t()) :: :all_ages | :nineteen_plus | :tbd
  @callback ticket_url(Meeseeks.Result.t()) :: String.t() | nil
end
