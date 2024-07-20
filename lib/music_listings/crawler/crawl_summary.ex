defmodule MusicListings.Crawler.CrawlStats do
  @moduledoc """
  Module that takes in a list of crawler payloads and
  summarizes the result of the crawl
  """
  alias MusicListings.Crawler.Payload

  defstruct [:new, :updated, :duplicate, :parse_errors, :errors, :errors_dump]

  @spec new(list(Payload)) :: __MODULE__
  def new(payloads) do
    Enum.reduce(
      payloads,
      %__MODULE__{
        duplicate: 0,
        new: 0,
        updated: 0,
        parse_errors: 0,
        errors: 0,
        errors_dump: []
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

      :parse_error ->
        Map.update!(acc, :parse_errors, &(&1 + 1))

      :save_error ->
        err = %{
          error: inspect(payload.error),
          parsed_event: inspect(payload.parsed_event)
        }

        acc
        |> Map.update!(:errors_dump, &[err | &1])
        |> Map.update!(:errors, &(&1 + 1))
    end
  end
end
