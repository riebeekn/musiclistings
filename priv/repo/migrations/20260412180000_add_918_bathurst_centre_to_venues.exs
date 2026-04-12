defmodule MusicListings.Repo.Migrations.Add918BathurstCentreToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('918 Bathurst Centre', 'Bathurst918Parser', true, '918 Bathurst Street', 'Toronto', 'Ontario', 'Canada', 'M5R 3G5', 'https://918bathurst.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d6229.359478561923!2d-79.41257049792067!3d43.66844420613502!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3491caa22b5d%3A0x2a4ed4e2f973baae!2s918%20Bathurst%20Centre%20for%20Culture%2C%20Arts%2C%20Media%20and%20Education!5e0!3m2!1sen!2sca!4v1776009677118!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = '918 Bathurst Centre'
    """)
  end
end
