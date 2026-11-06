defmodule MusicListings.Repo.Migrations.AddHemingwaysToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Hemingway''s', 'HemingwaysParser', true, '142 Cumberland St', 'Toronto', 'Ontario', 'Canada', 'M5R 1A8', 'https://hemingways.to/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.9475904547076!2d-79.3927925!3d43.6700598!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34a546c624ab%3A0x1f717a234e106332!2sHemingway''s%20Restaurant%20and%20Bar!5e0!3m2!1sen!2sca!4v1794007841067!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Hemingway''s'
    """)
  end
end
