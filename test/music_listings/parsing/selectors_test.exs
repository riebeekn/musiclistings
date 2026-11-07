defmodule MusicListings.Parsing.SelectorsTest do
  use ExUnit.Case, async: true

  import Meeseeks.CSS

  alias MusicListings.Parsing.Selectors

  describe "parse/1" do
    test "returns a document that can be queried" do
      assert {:ok, document} = Selectors.parse("<p class=\"title\">Some Band</p>")

      assert "Some Band" == document |> Selectors.match_one(css(".title")) |> Selectors.text()
    end

    test "returns an error for input that can't be parsed" do
      assert {:error, _reason} = Selectors.parse(<<0xFF, 0xFE>>)
    end
  end

  describe "text_lines/1" do
    test "returns each line of text broken up by <br>, skipping blank lines" do
      html = "<p> First line<br /> <br />Second line <br />Third</p>"

      assert ["First line", "Second line", "Third"] ==
               html |> Selectors.match_one(css("p")) |> Selectors.text_lines()
    end
  end

  describe "tag/1" do
    test "returns the lowercased tag name" do
      assert "p" ==
               "<div><P>Text</P></div>" |> Selectors.match_one(css("div > *")) |> Selectors.tag()
    end
  end
end
