defmodule MusicListings.Repo.Migrations.AddStandardTimeToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Standard Time', 'StandardTimeParser', true, '165 Geary Avenue', 'Toronto', 'Ontario', 'Canada', 'M6H 2B8', 'https://standardtime.to/club', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.9514756070944!2d-79.4358673!3d43.669979!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35e4b7b047c1%3A0xb628f51d2e2fdf62!2sStandard%20Time!5e0!3m2!1sen!2sca!4v1776007122806!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Standard Time'
    """)
  end
end
