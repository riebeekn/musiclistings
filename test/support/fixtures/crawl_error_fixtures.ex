defmodule MusicListings.CrawlErrorFixtures do
  @moduledoc false
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError

  def crawl_error_fixture(venue, crawl_summary, attrs \\ %{}) do
    attrs = valid_crawl_error_attributes(venue, crawl_summary, attrs)

    Repo.insert!(attrs)
  end

  defp valid_crawl_error_attributes(venue, crawl_summary, attrs) do
    params =
      Enum.into(attrs, %{
        venue_id: venue.id,
        crawl_summary_id: crawl_summary.id,
        raw_event: """
        #Meeseeks.Result<{ <a class="grid-item" href="/shows/lastsundays-acryc"> <div class="grid-image"> <div class="grid-image-inner-wrapper"> <img data-src="https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg" data-image="https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg" data-image-dimensions="3300x5100" data-image-focal-point="0.5,0.5" alt="EVERY LAST SUNDAY! - FREEFALL OPEN MIC" data-load="false" elementtiming="nbf-portfolio-grid-basic" src="https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg" width="3300" height="5100" sizes="(max-width: 767px) 100vw, 50vw" style="display:block;object-position: 50% 50%" srcset="https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=100w 100w, https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=300w 300w, https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=500w 500w, https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=750w 750w, https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=1000w 1000w, https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=1500w 1500w, https://images.squarespace-cdn.com/content/v1/61febfa76d87683c7044f770/1708318080588-637XE1PQXM1CT9MJVIJV/FF+Feb+2024-+SQ.jpg?format=2500w 2500w" loading="lazy" decoding="async" data-loader="sqs" /> </div> </div> <div class="portfolio-text"> <h3 class="portfolio-title">EVERY LAST SUNDAY! - FREEFALL OPEN MIC</h3> </div> </a> }>
        """
      })

    Ecto.Changeset.cast(%CrawlError{}, params, [
      :venue_id,
      :crawl_summary_id,
      :raw_event
    ])
  end
end
