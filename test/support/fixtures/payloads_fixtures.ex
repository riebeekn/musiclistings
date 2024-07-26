defmodule MusicListings.PayloadsFixtures do
  @moduledoc """
  Payloads related fixtures
  """
  alias MusicListings.Crawler.Payload
  alias MusicListings.Parsing.VenueParsers.DanforthMusicHallParser

  def load_payloads(source_file) do
    "#{File.cwd!()}/#{source_file}"
    |> Path.expand()
    |> File.read!()
    |> DanforthMusicHallParser.event_selector()
    |> Enum.map(&Payload.new/1)
  end
end
