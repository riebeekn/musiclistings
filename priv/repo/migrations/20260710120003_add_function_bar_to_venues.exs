defmodule MusicListings.Repo.Migrations.AddFunctionBarToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Function Bar', 'FunctionBarParser', true, '2291 Yonge Street', 'Toronto', 'Ontario', 'Canada', 'M4P 2C6', 'https://www.functionbar.ca', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2884.147999363932!2d-79.3982937!3d43.707473300000004!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b336e85d7760b%3A0xe7d9ba7cd20f4812!2sFunction%20Bar%20%2B%20Kitchen!5e0!3m2!1sen!2sca!4v1783730361789!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Function Bar'
    """)
  end
end
