defmodule MusicListings.Parsing.ChallengeBreakerTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.ChallengeBreaker

  test "a trip lasts until it is reset" do
    refute ChallengeBreaker.tripped?(:site)

    ChallengeBreaker.trip(:site)
    assert ChallengeBreaker.tripped?(:site)
    refute ChallengeBreaker.tripped?(:other_site)

    ChallengeBreaker.reset(:site)
    refute ChallengeBreaker.tripped?(:site)
  end

  test "a trip in an event task is seen by the rest of the crawl" do
    fn -> ChallengeBreaker.trip(:site) end |> Task.async() |> Task.await()

    assert ChallengeBreaker.tripped?(:site)
    assert fn -> ChallengeBreaker.tripped?(:site) end |> Task.async() |> Task.await()
  end

  test "a trip isn't seen by another crawl" do
    ChallengeBreaker.trip(:site)

    parent = self()
    spawn(fn -> send(parent, {:tripped?, ChallengeBreaker.tripped?(:site)}) end)

    assert_receive {:tripped?, false}
  end
end
