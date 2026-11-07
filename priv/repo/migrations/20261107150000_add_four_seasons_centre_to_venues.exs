defmodule MusicListings.Repo.Migrations.AddFourSeasonsCentreToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Four Seasons Centre for the Performing Arts', 'FourSeasonsCentreParser', true, '145 Queen St W', 'Toronto', 'Ontario', 'Canada', 'M5H 4G1', 'https://www.coc.ca/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d5773.768838218597!2d-79.385683!3d43.650573!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34cddfdbc1e1%3A0x6aeb453220fd1765!2sFour%20Seasons%20Centre%20for%20the%20Performing%20Arts!5e0!3m2!1sen!2sca!4v1794089280461!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Four Seasons Centre for the Performing Arts'
    """)
  end
end
