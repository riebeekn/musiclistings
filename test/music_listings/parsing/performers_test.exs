defmodule MusicListings.Parsing.PerformersTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers

  describe "new/1" do
    test "handles missing performers" do
      assert %Performers{headliner: nil, openers: []} == Performers.new([])
    end

    test "populates headliner when only headliner" do
      assert %Performers{headliner: "Bob Mintzer", openers: []} == Performers.new(["Bob Mintzer"])
    end

    test "populates both headliner and openers when both present" do
      assert %Performers{headliner: "Bob Mintzer", openers: ["Josh Redman", "Charlie Parker"]} ==
               Performers.new(["Bob Mintzer", "Josh Redman", "Charlie Parker"])
    end
  end
end
