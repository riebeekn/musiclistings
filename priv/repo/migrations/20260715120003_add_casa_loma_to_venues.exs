defmodule MusicListings.Repo.Migrations.AddCasaLomaToVenues do
  use Ecto.Migration

  # Casa Loma already exists as a known venue with parser_module_name 'n/a'
  # (seeded without a parser), so enable the parser via an upsert rather than a
  # plain insert - see EnableRedwoodTheatreParser for the same pattern.
  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Casa Loma', 'CasaLomaParser', 'true', '1 Austin Terrace', 'Toronto', 'Ontario', 'Canada', 'M5R 1X8', 'https://casaloma.ca', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2816.402790939276!2d-79.40955614644709!3d43.678023709448745!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b349dcf25a1b3%3A0x617cc8c102d6584f!2sCasa%20Loma!5e0!3m2!1sen!2sca!4v1784163282659!5m2!1sen!2sca')
    ON CONFLICT (name) DO UPDATE SET
      parser_module_name = EXCLUDED.parser_module_name,
      pull_events = EXCLUDED.pull_events,
      google_map_url = EXCLUDED.google_map_url
    """)
  end

  def down do
    execute("""
    UPDATE venues
    SET parser_module_name = 'n/a', pull_events = 'false'
    WHERE name = 'Casa Loma'
    """)
  end
end
