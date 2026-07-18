defmodule MusicListings.Repo.Migrations.AddFreeTimesCafeToVenues do
  use Ecto.Migration

  def up do
    execute("""
    INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, website, google_map_url)
    VALUES('Free Times Cafe', 'FreeTimesCafeParser', true, '320 College Street', 'Toronto', 'Ontario', 'Canada', 'M5T 1S3', 'https://www.freetimescafe.com/entertainment', 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2886.5428365657726!2d-79.402487!3d43.65767899999999!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34c1d0c81e2f%3A0xfcfeddf05a3f2417!2sFree%20Times%20Cafe!5e0!3m2!1sen!2sca!4v1784400614239!5m2!1sen!2sca')
    ON CONFLICT (name) DO NOTHING
    """)
  end

  def down do
    execute("""
    DELETE FROM venues WHERE name = 'Free Times Cafe'
    """)
  end
end
