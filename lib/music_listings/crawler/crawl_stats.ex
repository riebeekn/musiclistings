defmodule MusicListings.Crawler.CrawlStats do
  @moduledoc """
  Module that takes in a list of crawler payloads and
  summarizes the result of the crawl
  """
  alias MusicListings.Crawler.Payload

  defstruct [:new, :updated, :duplicate, :ignored, :parse_errors]

  @spec new(list(Payload) | any()) :: __MODULE__
  def new(payloads) do
    Enum.reduce(
      payloads,
      %__MODULE__{
        duplicate: 0,
        ignored: 0,
        new: 0,
        updated: 0,
        parse_errors: 0
      },
      fn payload, acc -> summarize_payload(payload, acc) end
    )
  end

  defp summarize_payload(payload, acc) do
    case payload.status do
      :ok ->
        case payload.operation do
          :created -> Map.update!(acc, :new, &(&1 + 1))
          :updated -> Map.update!(acc, :updated, &(&1 + 1))
          :noop -> Map.update!(acc, :duplicate, &(&1 + 1))
        end

      :ignore ->
        Map.update!(acc, :ignored, &(&1 + 1))

      :parse_error ->
        Map.update!(acc, :parse_errors, &(&1 + 1))
    end
  end
end
