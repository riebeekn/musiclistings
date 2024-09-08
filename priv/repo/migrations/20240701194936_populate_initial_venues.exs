defmodule MusicListings.Repo.Migrations.PopulateInitialVenues do
  use Ecto.Migration

  def up do
    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Budweiser Stage', 'BudweiserStageParser', true, '909 Lake Shore Blvd W', 'Toronto', 'Ontario', 'Cananda', 'M6K 3L3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11551.632718285297!2d-79.4152185!3d43.62927!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35108670b76b%3A0x88eb02c63d5c5f51!2sBudweiser%20Stage!5e0!3m2!1sen!2sca!4v1723163911267!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Cameron House', 'CameronHouseParser', true, '408 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 2A7', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.908992977485!2d-79.3975669!3d43.6486417!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34dc838caa77%3A0x4558bed57d3ab424!2sThe%20Cameron%20House!5e0!3m2!1sen!2sca!4v1723164038043!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Coca Cola Coliseum', 'CocaColaColiseumParser', true, '45 Manitoba Dr', 'Toronto', 'Ontario', 'Cananda', 'M6K 3C3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11550.310880355533!2d-79.4152538!3d43.6361473!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35051456dd69%3A0x2030d3806ac33542!2sCoca-Cola%20Coliseum!5e0!3m2!1sen!2sca!4v1723164079858!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('CODA', 'CodaParser', true, '794 Bathurst St', 'Toronto', 'Ontario', 'Cananda', 'M5R 3G1', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11544.686755882265!2d-79.4114716!3d43.665399!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b349232fbcfc5%3A0x60c01d5b1d632cfc!2sCoda!5e0!3m2!1sen!2sca!4v1723164130490!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Danforth Music Hall', 'DanforthMusicHallParser', true, '147 Danforth Ave', 'Toronto', 'Ontario', 'Cananda', 'M4K 1N2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11542.600783125072!2d-79.3570083!3d43.6762444!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cc9ff2a975d1%3A0x938fe9b4a172a476!2sDanforth%20Music%20Hall!5e0!3m2!1sen!2sca!4v1723164178157!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Drake Underground', 'DrakeUndergroundParser', true, '1150 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M6J 1J3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.94700620446!2d-79.4246705!3d43.6432424!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b35001b391e01%3A0xad1846225f752a90!2sUnderground!5e0!3m2!1sen!2sca!4v1723164236052!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('History', 'HistoryParser', true, '1663 Queen St E', 'Toronto', 'Ontario', 'Cananda', 'M4L 1G5', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11544.413487645455!2d-79.3135141!3d43.6668199!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb9b12712f9d%3A0x994d0b5d9614f7e4!2sHISTORY!5e0!3m2!1sen!2sca!4v1723164288391!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Horseshoe Tavern', 'HorseshoeTavernParser', true, '370 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 2A2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.82660963459!2d-79.3958951!3d43.6490702!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34db14b774ed%3A0x4db03320e6994e59!2sHorseshoe%20Tavern!5e0!3m2!1sen!2sca!4v1723164332802!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code)
      VALUES('Lee''s Palace', 'LeesPalaceParser', true, '529 Bloor St W', 'Toronto', 'Ontario', 'Cananda', 'M5S 1Y5')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Great Hall', 'GreatHallParser', true, '1087 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M6J 1H3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.90901949285!2d-79.4220832!3d43.64344!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3501d6f80459%3A0xc345dac1cd2ccc7b!2sThe%20Great%20Hall!5e0!3m2!1sen!2sca!4v1723164415175!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Massey Hall', 'MasseyHallParser', true, '178 Victoria St', 'Toronto', 'Ontario', 'Cananda', 'M5B 1T7', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.872492336903!2d-79.3789669!3d43.6540326!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb34a2b3eeff%3A0x7f28debbb1128959!2sMassey%20Hall!5e0!3m2!1sen!2sca!4v1723164465969!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Roy Thomson Hall', 'RoyThomsonHallParser', true, '60 Simcoe St', 'Toronto', 'Ontario', 'Cananda', 'M5J 2H5', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.300213716035!2d-79.3864069!3d43.6466068!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34d3d618e077%3A0x33e5adb630149b89!2sRoy%20Thomson%20Hall!5e0!3m2!1sen!2sca!4v1723164510518!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('TD Music Hall', 'TDMusicHallParser', true, '178 Victoria St', 'Toronto', 'Ontario', 'Cananda', 'M5B 1T7', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.881240984647!2d-79.3789995!3d43.6539871!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb6742d82ae9%3A0xa71f3d1eb2166a68!2sTD%20Music%20Hall!5e0!3m2!1sen!2sca!4v1723164553289!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Queen Elizabeth Theatre', 'QueenElizabthTheatreParser', true, '190 Princes'' Blvd', 'Toronto', 'Ontario', 'Cananda', 'M6K 3C3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11550.972021936273!2d-79.4213438!3d43.6327076!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b350894dedf69%3A0x24a9ad69ec769b8d!2sQueen%20Elizabeth%20Theatre!5e0!3m2!1sen!2sca!4v1723164596355!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Rebel', 'RebelParser', true, '11 Polson St First Floor', 'Toronto', 'Ontario', 'Cananda', 'M5A 1A4', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11549.40454689178!2d-79.3545641!3d43.6408623!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb1ed1b7ec7f%3A0x12eae65b79171bda!2sRebel!5e0!3m2!1sen!2sca!4v1723164642638!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Axis Club', 'AxisClubParser', true, '722 College St', 'Toronto', 'Ontario', 'Cananda', 'M6G 1C4', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.626777341746!2d-79.4192684!3d43.6553105!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3552340fa479%3A0x62e391a9a5073262!2sThe%20Axis%20Club%20Theatre!5e0!3m2!1sen!2sca!4v1723164693549!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Baby G', 'BabyGParser', true, '1608 Dundas St W', 'Toronto', 'Ontario', 'Cananda', 'M6K 1T8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.64426810234!2d-79.4354036!3d43.6500186!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b3451ed9d507f%3A0xfb269ac4d7d6d14c!2sThe%20Baby%20G!5e0!3m2!1sen!2sca!4v1723164732943!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Concert Hall', 'ConcertHallParser', true, '888 Yonge St', 'Toronto', 'Ontario', 'Cananda', 'M4W 2J2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11543.204552570545!2d-79.3881371!3d43.6731055!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34aece529b9f%3A0x3f1eec914667ac54!2sThe%20Concert%20Hall!5e0!3m2!1sen!2sca!4v1723164787974!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Garrison', 'GarrisonParser', true, '1197 Dundas St West', 'Toronto', 'Ontario', 'Cananda', 'M6J 1X3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.814477983911!2d-79.4223722!3d43.6491333!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34f8de16261f%3A0xe22bed0e7066db1d!2sThe%20Garrison!5e0!3m2!1sen!2sca!4v1723163576912!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Monarch Tavern', 'MonarchTavernParser', true, '12 Clinton St', 'Toronto', 'Ontario', 'Cananda', 'M6J 2N8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.865281907465!2d-79.4135664!3d43.6540701!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34efd1b70fa7%3A0xcc27a1658793990!2sMonarch%20Tavern!5e0!3m2!1sen!2sca!4v1723164829384!5m2!1sen!2s')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Opera House', 'OperaHouseParser', true, '735 Queen St E', 'Toronto', 'Ontario', 'Cananda', 'M4M 1H1', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11545.934537380044!2d-79.3487593!3d43.6589105!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb6db7bf429b%3A0xaede0e797c7ff4a7!2sThe%20Opera%20House!5e0!3m2!1sen!2sca!4v1723164869621!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Phoenix Concert Theatre', 'PhoenixParser', true, '410 Sherbourne St', 'Toronto', 'Ontario', 'Cananda', 'M5X 1K2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11544.838128313198!2d-79.3740471!3d43.6646119!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb4e8868b1cb%3A0x501620a745c00dc2!2sPhoenix%20Concert%20Theatre!5e0!3m2!1sen!2sca!4v1723164915920!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Rex', 'RexParser', true, '194 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 1Z1', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.533177414563!2d-79.3885233!3d43.6505964!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34ce31391853%3A0x77131de829a5e7a9!2sThe%20Rex%20Hotel%20Jazz%20and%20Blues%20Bar!5e0!3m2!1sen!2sca!4v1723164951565!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Velvet Underground', 'VelvetUndergroundParser', true, '508 Queen St W', 'Toronto', 'Ontario', 'Cananda', 'M5V 2B3', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.051475222872!2d-79.4015411!3d43.6479006!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34dd960a0175%3A0xa15eac3271fffc93!2sVelvet%20Underground!5e0!3m2!1sen!2sca!4v1723164988781!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('El Mocambo', 'ElMocamboParser', true, '464 Spadina Ave.', 'Toronto', 'Ontario', 'Cananda', 'M5T 2G8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.18824861766!2d-79.4002005!3d43.6575911!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34c1a9bc5443%3A0xa5ec8d341c25ed15!2sEl%20Mocambo!5e0!3m2!1sen!2sca!4v1723165033014!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Pilot', 'PilotParser', true, '22 Cumberland St', 'Toronto', 'Ontario', 'Cananda', 'M4W 1J5', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11543.61516293805!2d-79.3882631!3d43.6709707!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34ae564d9311%3A0xf45363ccd28e7644!2sThe%20Pilot!5e0!3m2!1sen!2sca!4v1723165071692!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Jazz Bistro', 'JazzBistroParser', true, '251 Victoria St', 'Toronto', 'Ontario', 'Cananda', 'M5B 1T8', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11546.533385293684!2d-79.3790595!3d43.6557962!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb34dbfc8493%3A0x35ccd9801faa1d05!2sJazz%20Bistro!5e0!3m2!1sen!2sca!4v1723165106863!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('The Dakota Tavern', 'DakotaTavernParser', true, '249 Ossington Ave', 'Toronto', 'Ontario', 'Cananda', 'M6J 3A1', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11547.697352040219!2d-79.420701!3d43.6497425!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34f96e0da011%3A0x709a23533c585d54!2sThe%20Dakota%20Tavern!5e0!3m2!1sen!2sca!4v1723165144097!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Rogers Centre', 'RogersParser', true, '1 Blue Jays Way', 'Toronto', 'Ontario', 'Cananda', 'M5V 1J1', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11549.26738866233!2d-79.3894282!3d43.6415758!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x882b34d7b66a4a51%3A0xe210b2f6fe0b1405!2sRogers%20Centre!5e0!3m2!1sen!2sca!4v1723165180612!5m2!1sen!2sca')
    """

    execute """
      INSERT INTO venues(name, parser_module_name, pull_events, street, city, province, country, postal_code, google_map_url)
      VALUES('Scotiabank Arena', 'ScotiabankParser', true, '40 Bay St.', 'Toronto', 'Ontario', 'Cananda', 'M5J 2X2', 'https://www.google.com/maps/embed?pb=!1m14!1m8!1m3!1d11548.904002007008!2d-79.3790989!3d43.6434661!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x89d4cb2b5935bf09%3A0x5842d0e7d5669410!2sScotiabank%20Arena!5e0!3m2!1sen!2sca!4v1723165219207!5m2!1sen!2sca')
    """
  end

  def down do
    execute "DELETE FROM venues"
  end
end
