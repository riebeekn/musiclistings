defmodule MusicListings.Repo.Migrations.AddCabanaToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Cabana Pool Bar', 'CabanaParser', true, '11 Polson St', 'Toronto', 'Ontario', 'Canada', 'M5A 1A4', 'https://cabanatoronto.com/', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2887.3552168380834!2d-79.3545752!3d43.6407774!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb1ed8d919cb%3A0xfffc3d6a9944dcb4!2sCabana!5e0!3m2!1sen!2sca!4v1783780203412!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Cabana Pool Bar'
    """)
  end
end
