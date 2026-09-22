defmodule MusicListings.Parsing.LookupFailuresTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.LookupFailures

  describe "take/0" do
    test "returns nothing when nothing was recorded" do
      assert [] == LookupFailures.take()
    end

    test "returns the recorded failures, oldest first, and clears them" do
      :ok = LookupFailures.record([:time, :ticket_url], "first")
      :ok = LookupFailures.record([:ticket_url], "second")

      assert [
               %{fields: [:time, :ticket_url], message: "first"},
               %{fields: [:ticket_url], message: "second"}
             ] == LookupFailures.take()

      assert [] == LookupFailures.take()
    end

    test "only sees failures recorded in the calling process" do
      :ok = LookupFailures.record([:ticket_url], "mine")

      assert [] == (&LookupFailures.take/0) |> Task.async() |> Task.await()
      assert [%{message: "mine"}] = LookupFailures.take()
    end
  end
end
