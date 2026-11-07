defmodule MusicListings.Parsing.Selectors do
  @moduledoc """
  Selector helpers. Parsers go through this module rather than calling Meeseeks directly,
  importing `Meeseeks.CSS` only for `css/1`.
  """

  @doc """
  Parses HTML into a document, for a page that's queried more than once. The other functions also
  take raw HTML, parsing it on each call.
  """
  def parse(html) do
    case Meeseeks.parse(html) do
      {:error, _reason} = error -> error
      document -> {:ok, document}
    end
  end

  def all_matches(content, selector) do
    Meeseeks.all(content, selector)
  end

  def match_one(content, selector) do
    Meeseeks.one(content, selector)
  end

  def url(content, url_selector) do
    content
    |> Meeseeks.one(url_selector)
    |> case do
      nil -> nil
      result -> Meeseeks.Result.attr(result, "href")
    end
  end

  def id(%Meeseeks.Result{} = content, id_selector) do
    content
    |> Meeseeks.one(id_selector)
    |> Meeseeks.Result.attr("id")
  end

  def class(%Meeseeks.Result{} = content, class_selector) do
    content
    |> Meeseeks.one(class_selector)
    |> Meeseeks.Result.attr("class")
  end

  def attr(%Meeseeks.Result{} = content, attr) do
    Meeseeks.Result.attr(content, attr)
  end

  def text(%Meeseeks.Result{} = event, text_selector) do
    event
    |> Meeseeks.one(text_selector)
    |> Meeseeks.text()
  end

  def text(content) when is_list(content) do
    Enum.map(content, &Meeseeks.text/1)
  end

  def text(content) do
    Meeseeks.text(content)
  end

  def data(content) when is_list(content) do
    Enum.map(content, &Meeseeks.data/1)
  end

  def data(content) do
    Meeseeks.data(content)
  end
end
