defmodule MusicListings.Repo.Migrations.AddSauceToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Sauce on the Danforth', 'SauceParser', true, '1376 Danforth Avenue', 'Toronto', 'Ontario', 'Canada', 'M4J 1M9', 'https://sauceonthedanforth.com', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2885.345149309725!2d-79.3282509!3d43.68258739999999!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc64b7d55121%3A0x7f950ae0cf42904d!2sSauce%20on%20Danforth!5e0!3m2!1sen!2sca!4v1783732207115!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Sauce on the Danforth'
    """)
  end
end
