defmodule MusicListings.Repo.Migrations.AddRoyalConservatoryVenuesToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Koerner Hall', 'KoernerHallParser', true, '273 Bloor Street West', 'Toronto', 'Ontario', 'Canada', 'M5S 1W2', 'https://www.rcmusic.com/performance/plan-your-visit/venues/koerner-hall', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.0624164041633!2d-79.3961722!3d43.6676717!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34bc9c4b1ad9%3A0x183cfcf980634c7b!2sKoerner%20Hall!5e0!3m2!1sen!2sca!4v1785960401840!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)

    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Mazzoleni Concert Hall', 'MazzoleniConcertHallParser', true, '273 Bloor Street West', 'Toronto', 'Ontario', 'Canada', 'M5S 1W2', 'https://www.rcmusic.com/performance/plan-your-visit/venues/mazzoleni-concert-hall-in-ihnatowycz-hall', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d1443.0121152974818!2d-79.39716062401199!3d43.66846588337221!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34bb6b6d3d2d%3A0xb4e8d876c09115fd!2sMazzoleni%20Hall!5e0!3m2!1sen!2sca!4v1785960439700!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)

    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Temerty Theatre', 'TemertyTheatreParser', true, '273 Bloor Street West', 'Toronto', 'Ontario', 'Canada', 'M5S 1W2', 'https://www.rcmusic.com/performance/plan-your-visit/venues/temerty-theatre', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.057449579984!2d-79.3961594!3d43.667775!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34bb6dd98dbb%3A0x49080c5cbaa7b3d4!2s273%20Bloor%20St%20W%2C%20Toronto%2C%20ON%20M5S%201W2!5e0!3m2!1sen!2sca!4v1785960564238!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name IN ('Koerner Hall', 'Mazzoleni Concert Hall', 'Temerty Theatre')
    """)
  end
end
