defmodule MusicListings.Repo.Migrations.AddLowBarToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Low Bar', 'LowBarParser', true, '1426 Bloor Street West', 'Toronto', 'Ontario', 'Canada', 'M6P 3L4', 'https://ma.to/venue/l0w_bar', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.5587918529272!2d-79.4480359!3d43.657347099999996!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35000a4efe21%3A0x600ebe15395d45e!2sLow%20Bar!5e0!3m2!1sen!2sca!4v1784247388386!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Low Bar'
    """)
  end
end
