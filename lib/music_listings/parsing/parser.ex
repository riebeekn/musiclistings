defmodule MusicListings.Parsing.Parser do
  import Meeseeks.CSS
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

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

  def event_selector(body, event_selector) do
    Meeseeks.all(body, css(event_selector))
  end

  def next_page_url(body, next_page_selector) do
    body
    |> Meeseeks.one(css(next_page_selector))
    |> case do
      nil -> nil
      result -> Meeseeks.Result.attr(result, "href")
    end
  end

  def event_id(%Meeseeks.Result{} = event, event_id_selector) do
    event
    |> Meeseeks.one(css(event_id_selector))
    |> Meeseeks.Result.attr("id")
  end

  def event_title(%Meeseeks.Result{} = event, event_title_selector) do
    event
    |> Meeseeks.one(css(event_title_selector))
    |> Meeseeks.Result.text()
  end

  def performers(%Meeseeks.Result{} = event, performers_selector) do
    event
    |> Meeseeks.all(css(performers_selector))
    |> Enum.map(&Meeseeks.Result.text/1)
    |> Performers.new()
  end

  def ticket_url(%Meeseeks.Result{} = event, ticket_url_selector) do
    event
    |> Meeseeks.one(css(ticket_url_selector))
    |> Meeseeks.Result.attr("href")
  end

  def convert_event_time_string_to_time(time_string) do
    time_string
    |> String.trim()
    |> String.downcase()
    |> String.split(":")
    |> case do
      [hour_string, minute_string] ->
        hour =
          hour_string
          |> String.to_integer()
          |> maybe_adjust_for_pm(minute_string)

        minute =
          minute_string
          |> String.replace("pm", "")
          |> String.trim()
          |> String.to_integer()

        Time.new!(hour, minute, 0)

      _tbd ->
        nil
    end
  end

  defp maybe_adjust_for_pm(hour, minute_string) do
    if String.contains?(minute_string, "pm") do
      hour + 12
    else
      hour
    end
  end

  defdelegate convert_price_string_to_price(price_string), to: Price, as: :new

  def convert_age_restriction_string_to_enum(age_restriction_string) do
    age_restriction_string
    |> String.trim()
    |> String.downcase()
    |> case do
      "all" -> :all_ages
      "all ages" -> :all_ages
      "all ages event" -> :all_ages
      "19+" -> :nineteen_plus
      "19+ event" -> :nineteen_plus
    end
  end
end
