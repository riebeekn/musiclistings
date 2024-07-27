defmodule MusicListings.Parsing.VenueParser do
  @moduledoc """
  Module that defines the behaviour for a Parser
  """
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @doc """
  The URL to pull events from
  """
  @callback source_url() :: String.t()
  @doc """
  The location of the local data file used for local testing
  """
  @callback example_data_file_location() :: String.t()
  @doc """
  A list of all the events
  """
  @callback events(String.t()) :: [Meeseeks.Result.t()] | {:error, Meeseeks.Error.t()}
  @doc """
  The URL for the next page of results
  """
  @callback next_page_url(String.t()) :: String.t() | nil
  @doc """
  The id of the event
  """
  @callback event_id(Meeseeks.Result.t()) :: String.t()
  @doc """
  The event title
  """
  @callback event_title(Meeseeks.Result.t()) :: String.t()
  @doc """
  The event performers, split out to headliner and openers
  """
  @callback performers(Meeseeks.Result.t()) :: Performers.t()
  @doc """
  The date of the event
  """
  @callback event_date(Meeseeks.Result.t()) :: Date.t()
  @doc """
  The time of the event
  """
  @callback event_time(Meeseeks.Result.t()) :: Time.t() | nil
  @doc """
  The event price
  """
  @callback price(Meeseeks.Result.t()) :: Price.t()
  @doc """
  Age restrictions for the event
  """
  @callback age_restriction(Meeseeks.Result.t()) :: :all_ages | :nineteen_plus | :tbd
  @doc """
  The ticket URL for the event
  """
  @callback ticket_url(Meeseeks.Result.t()) :: String.t() | nil
end
