defmodule MusicListings.TitleSimilarity do
  @moduledoc """
  Compares event titles that describe the same show but are written differently.

  Two independent concerns need this. The TicketNetwork affiliate pass matches a
  catalog item's name against our own title for the same night
  (`MusicListings.Affiliates.TicketNetwork.Matcher`), and curation looks for the
  same show listed twice on one date (`MusicListings.Curation`) - a venue and its
  upstairs room both publishing "Slow Teeth w/ Waxlimbs" and "Slow Teeth with
  Waxlimbs".

  Both reduce to the same question, so the normalisation and scoring live here
  and each caller keeps its own acceptance threshold: a wrong affiliate link is
  worse than none, while a missed duplicate only costs a review.
  """

  # Words that carry no identifying signal in an event title.
  @stopwords ~w(the a an and with w presents presented by live tour feat featuring ft)

  # Applied before anything else, to reconcile naming conventions that differ
  # between TicketNetwork and the venue's own listings.
  @aliases %{"toronto symphony orchestra" => "tso"}

  # Substring containment is a strong signal for "Kevin Atwater" inside
  # "Kevin Atwater - Support: Jessie Mazin", but a meaningless one for very
  # short names, so it only applies above this length.
  @min_containment_length 5

  @doc """
  Reduces a title to its identifying words, so that cosmetic differences between
  two spellings of the same show don't defeat comparison.
  """
  @spec normalize(String.t() | nil) :: String.t()
  def normalize(nil), do: ""

  def normalize(title) do
    title
    |> String.downcase()
    |> fold_accents()
    |> apply_aliases()
    |> strip_role_suffix()
    |> take_leading_segment()
    |> String.replace(~r/[^a-z0-9 ]/u, " ")
    |> drop_stopwords()
  end

  @doc """
  Similarity of two titles, from 0.0 to 1.0.
  """
  @spec score(String.t() | nil, String.t() | nil) :: float()
  def score(left, right) do
    left = normalize(left)
    right = normalize(right)

    cond do
      left == "" or right == "" ->
        0.0

      left == right ->
        1.0

      numbers_conflict?(left, right) ->
        0.0

      true ->
        Enum.max([
          jaccard(left, right),
          String.jaro_distance(left, right),
          containment(left, right)
        ])
    end
  end

  defp fold_accents(string) do
    string
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/[\x{0300}-\x{036F}]/u, "")
  end

  defp apply_aliases(string) do
    Enum.reduce(@aliases, string, fn {from, to}, acc -> String.replace(acc, from, to) end)
  end

  # "Hugel - Artist" and "Cardinals - Band" are TicketNetwork's way of
  # disambiguating acts whose name is an everyday word.
  defp strip_role_suffix(string) do
    String.replace(string, ~r/\s+-\s+(artist|band)$/u, "")
  end

  # Drops trailing tour names and support billing ("Altin Gun - AMERICA TOUR
  # 2026"), but only when what precedes them is substantial enough to identify
  # the act on its own - otherwise "TSO - Messiah" would collapse to "TSO".
  defp take_leading_segment(string) do
    [leading | _rest] = String.split(string, ~r/:|–|\s-\s/u, parts: 2)
    trimmed = String.trim(leading)

    if String.length(trimmed) > 4, do: trimmed, else: string
  end

  defp drop_stopwords(string) do
    string
    |> String.split(~r/\s+/u, trim: true)
    |> Enum.reject(&(&1 in @stopwords))
    |> Enum.join(" ")
  end

  # Titles that both carry numbers, but different ones, are different events -
  # "Rachmaninoff Piano Concerto No. 3" and "No. 4" are one character apart and
  # otherwise identical, which character-level similarity happily scores at 0.88.
  #
  # Only applied when both sides have numbers: our titles often carry a show time
  # or tour year the catalog omits ("Bingo Loco Toronto @ Annabel's Late Show
  # (9:30PM)"), and those are still the same event.
  defp numbers_conflict?(left, right) do
    left_numbers = numbers(left)
    right_numbers = numbers(right)

    left_numbers != [] and right_numbers != [] and left_numbers != right_numbers
  end

  defp numbers(string) do
    ~r/\d+/
    |> Regex.scan(string)
    |> List.flatten()
    |> Enum.sort()
  end

  defp jaccard(left, right) do
    left_tokens = left |> String.split(" ", trim: true) |> MapSet.new()
    right_tokens = right |> String.split(" ", trim: true) |> MapSet.new()

    union_size = left_tokens |> MapSet.union(right_tokens) |> MapSet.size()
    shared_size = left_tokens |> MapSet.intersection(right_tokens) |> MapSet.size()

    if union_size == 0, do: 0.0, else: shared_size / union_size
  end

  defp containment(left, right) do
    shorter_length = min(String.length(left), String.length(right))

    if shorter_length >= @min_containment_length and
         (String.contains?(left, right) or String.contains?(right, left)) do
      0.95
    else
      0.0
    end
  end
end
