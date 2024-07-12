defmodule MusicListings.Emails.LatestCrawlResults do
  @moduledoc """
  Email that sends latest crawl result summary
  """
  use MusicListings.Mailer

  alias MusicListingsSchema.CrawlSummary

  def new_email(crawl_summary) do
    new()
    |> to(Application.get_env(:music_listings, :admin_email))
    |> from({"Toronto Music Listings", "no-reply@example.com"})
    |> subject("Latest Crawl Results")
    |> body(mjml(%{crawl_summary: crawl_summary}))
  end

  defp mjml(assigns) do
    ~H"""
    <.header>
      Latest Crawl Results - <%= DateTime.to_string(@crawl_summary.inserted_at) %>
    </.header>
    <.text>
      <ul>
        <li>New events: <%= @crawl_summary.new %></li>
        <li>Updated events: <%= @crawl_summary.updated %></li>
        <li>Duplicate events: <%= @crawl_summary.duplicate %></li>
        <li>Parse errors: <%= @crawl_summary.parse_errors %></li>
        <li>Other errors: <%= @crawl_summary.errors %></li>
      </ul>
    </.text>
    """
  end

  def preview do
    %CrawlSummary{
      duplicate: 100,
      new: 4,
      updated: 1,
      parse_errors: 3,
      errors: 2,
      inserted_at: DateTime.utc_now()
    }
    |> new_email()
  end

  def preview_details do
    [
      title: "Latest Crawl Results",
      description: "Sent daily via the Oban Job that executes the crawler",
      tags: [category: "Admin"]
    ]
  end
end
