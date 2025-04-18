defmodule MusicListings.Parsing.Selectors do
  @moduledoc """
  Selector helpers
  """
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
