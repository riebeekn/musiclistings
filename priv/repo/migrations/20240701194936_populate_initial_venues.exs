defmodule MusicListings.Repo.Migrations.PopulateInitialVenues do
  use Ecto.Migration

  def up do
    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Budweiser Stage', 'MusicListings.Parsing.BudweiserStageParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Cameron House', 'MusicListings.Parsing.CameronHouseParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Coca Cola Coliseum', 'MusicListings.Parsing.CocaColaColiseumParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('CODA', 'MusicListings.Parsing.CodaParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Danforth Music Hall', 'MusicListings.Parsing.DanforthMusicHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Drake Underground', 'MusicListings.Parsing.DrakeUndergroundParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Hard Luck Bar', 'MusicListings.Parsing.HardLuckBarParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('History', 'MusicListings.Parsing.HistoryParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Horseshoe Tavern', 'MusicListings.Parsing.HorseshoeTavernParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Lees Palace', 'MusicListings.Parsing.LeesPalaceParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Longboat Hall', 'MusicListings.Parsing.LongboatHallParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Lula Lounge', 'MusicListings.Parsing.LulaLoungeParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Massey Hall', 'MusicListings.Parsing.MasseyHallParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Queen Elizabth Theatre', 'MusicListings.Parsing.QueenElizabthTheatreParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Rebel', 'MusicListings.Parsing.RebelParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Rum Runners', 'MusicListings.Parsing.Rum Runners', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Axis Club', 'MusicListings.Parsing.TheAxisClubParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Baby G', 'MusicListings.Parsing.TheBabyGParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Concert Hall', 'MusicListings.Parsing.TheConcertHallParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Garrison', 'MusicListings.Parsing.TheGarrisonParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Monarch Tavern', 'MusicListings.Parsing.TheMonarchTavernParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Opera House', 'MusicListings.Parsing.TheOperaHouseParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Phoenix', 'MusicListings.Parsing.ThePhoenixParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Rex', 'MusicListings.Parsing.TheRexParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Velvet Underground', 'MusicListings.Parsing.VelvetUndergroundParser', true)"
  end

  def down do
    execute "DELETE FROM venues"
  end
end
