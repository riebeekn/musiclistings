defmodule MusicListings.Repo.Migrations.AddTapestryToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Tapestry', 'TapestryParser', true, '224 Augusta Avenue', 'Toronto', 'Ontario', 'Canada', 'M5T 2L6', 'https://www.instagram.com/tapestry_to', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.6739276022254!2d-79.402382!3d43.654952!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b358841900c6f%3A0xf8d0ef806deea9fb!2sTapestry!5e0!3m2!1sen!2sca!4v1784247706942!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Tapestry'
    """)
  end
end
