defmodule MusicListings.Parsing.PriceTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Price

  describe "unknown/0" do
    test "returns default when unknown" do
      assert %Price{lo: nil, hi: nil, format: :unknown} == Price.unknown()
    end
  end

  describe "new/1" do
    test "handles missing price" do
      assert %Price{lo: nil, hi: nil, format: :unknown} == Price.new(nil)
    end

    test "cleans and parses price strings" do
      assert %Price{lo: Decimal.new("30.00"), hi: Decimal.new("50.00"), format: :range} ==
               Price.new("$30.00-$50.00 (plus service fees)")

      assert %Price{lo: Decimal.new("30.00"), hi: Decimal.new("30.00"), format: :fixed} ==
               Price.new("$30.00-$30.00 (plus fees)")

      assert %Price{lo: Decimal.new("25.00"), hi: Decimal.new("30.00"), format: :range} ==
               Price.new("Price: $25.00-$30.00 (plus service fees) ")

      assert %Price{lo: Decimal.new("40.00"), hi: Decimal.new("40.00"), format: :variable} ==
               Price.new("$40.00 + (plus service fees)")
    end
  end
end
