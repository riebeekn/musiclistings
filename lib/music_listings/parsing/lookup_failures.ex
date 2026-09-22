defmodule MusicListings.Parsing.LookupFailures do
  @moduledoc """
  Lets a parser report that it couldn't determine some of an event's fields
  because a follow-up request failed (e.g. a detail page behind a Cloudflare
  challenge), as opposed to the venue genuinely not listing them.

  The distinction matters to the crawler in two ways:

    * `MusicListings.Crawler.EventStorage` keeps the stored value of a field
      reported here rather than overwriting it with `nil`, so a blocked night
      doesn't erase a ticket link an earlier crawl found;
    * `MusicListings.Crawler` rolls the failures into a `:lookup_error` in the
      crawl report, so the gaps are visible rather than silent.

  Failures are held in the process dictionary.  `MusicListings.Crawler.EventParser`
  parses each event in its own task, so a parser that calls `record/2` while
  parsing an event attributes the failure to that event without having to
  thread anything through its return values.
  """

  @key {__MODULE__, :failures}

  @type failure :: %{fields: [atom()], message: String.t()}

  @doc """
  Records that `fields` couldn't be determined for the event being parsed.
  """
  @spec record([atom()], String.t()) :: :ok
  def record(fields, message) do
    Process.put(@key, [%{fields: fields, message: message} | Process.get(@key, [])])
    :ok
  end

  @doc """
  Returns the failures recorded in this process, oldest first, and clears them.
  """
  @spec take :: [failure()]
  def take do
    @key
    |> Process.delete()
    |> Kernel.||([])
    |> Enum.reverse()
  end
end
