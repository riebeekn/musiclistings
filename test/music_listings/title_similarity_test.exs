defmodule MusicListings.TitleSimilarityTest do
  use ExUnit.Case, async: true

  alias MusicListings.TitleSimilarity

  describe "normalize/2 - duplicate listings seen in production" do
    test "'w/' and 'with' reduce to the same title" do
      assert TitleSimilarity.normalize("Slow Teeth w/ Waxlimbs") ==
               TitleSimilarity.normalize("Slow Teeth with Waxlimbs")
    end

    test "a separator swapped for '&' reduces to the same title" do
      assert TitleSimilarity.normalize("Psycroptic, Inferi, Cognitive & Summoning The Lich") ==
               TitleSimilarity.normalize("Psycroptic, Inferi, Cognitive, Summoning The Lich")
    end
  end

  describe "score/2" do
    test "scores real duplicate pairs at the top of the range" do
      assert TitleSimilarity.score("Slow Teeth w/ Waxlimbs", "Slow Teeth with Waxlimbs") == 1.0
      assert TitleSimilarity.score("Silly Goose w/ Cheem", "Silly Goose with Cheem") == 1.0
    end

    test "scores unrelated shows on the same night well below the duplicate threshold" do
      assert TitleSimilarity.score("Loreena McKennitt", "Amanda Marshall") < 0.85
    end
  end
end
