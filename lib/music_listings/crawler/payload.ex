defmodule MusicListings.Crawler.Payload do
  @moduledoc """
  Module to represent an event as it moves thru-out the
  crawling process
  """

  @type t :: %__MODULE__{
          status: :ok | :parse_error | :storage_error,
          operation: :created | :updated | :noop,
          raw_event: Meeseeks.Result,
          parsed_event: MusicListingsSchema.Event,
          persisted_event: MusicListingsSchema.Event
        }

  defstruct [:raw_event, :parsed_event, :status, :error, :persisted_event, :operation]

  def new(meeseeks_event_selector_result) do
    %__MODULE__{raw_event: meeseeks_event_selector_result}
  end

  def set_parse_error(%__MODULE__{} = payload, error) do
    %{payload | status: :parse_error, error: error}
  end

  def set_parsed_event(%__MODULE__{} = payload, parsed_event) do
    %{payload | status: :ok, parsed_event: parsed_event}
  end

  def set_persisted_event(%__MODULE__{} = payload, :noop) do
    %{payload | operation: :noop}
  end

  def set_persisted_event(%__MODULE__{} = payload, persisted_event) do
    %{payload | persisted_event: persisted_event}
  end

  def set_operation(%__MODULE__{} = payload, operation) do
    %{payload | operation: operation}
  end
end
