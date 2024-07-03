defmodule MusicListings.Parsing.VelvetUndergroundParserTest do
  use ExUnit.Case, async: true
  import Meeseeks.CSS
  alias MusicListings.Parsing.VelvetUndergroundParser

  describe "parse/1" do
    setup do
      index_file_path = Path.expand("#{File.cwd!()}/test/data/velvet_underground/index.html")

      single_event_file_path =
        Path.expand("#{File.cwd!()}/test/data/velvet_underground/single_event.html")

      index = File.read!(index_file_path)
      event = File.read!(single_event_file_path)
      %{index: index, event: event}
    end
  end
end
