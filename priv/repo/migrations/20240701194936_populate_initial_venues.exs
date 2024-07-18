defmodule MusicListings.Repo.Migrations.PopulateInitialVenues do
  use Ecto.Migration

  def up do
    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Budweiser Stage', 'MusicListings.Parsing.BudweiserStageParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Cameron House', 'MusicListings.Parsing.CameronHouseParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Coca Cola Coliseum', 'MusicListings.Parsing.CocaColaColiseumParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('CODA', 'MusicListings.Parsing.CodaParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Danforth Music Hall', 'MusicListings.Parsing.DanforthMusicHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Drake Underground', 'MusicListings.Parsing.DrakeUndergroundParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Hard Luck Bar', 'MusicListings.Parsing.HardLuckBarParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('History', 'MusicListings.Parsing.HistoryParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Horseshoe Tavern', 'MusicListings.Parsing.HorseshoeTavernParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Lee''s Palace', 'MusicListings.Parsing.LeesPalaceParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Great Hall', 'MusicListings.Parsing.GreatHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Lula Lounge', 'MusicListings.Parsing.LulaLoungeParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Massey Hall', 'MusicListings.Parsing.MasseyHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Roy Thomson Hall', 'MusicListings.Parsing.RoyThomsonHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('TD Music Hall', 'MusicListings.Parsing.TDMusicHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Queen Elizabeth Theatre', 'MusicListings.Parsing.QueenElizabthTheatreParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Rebel', 'MusicListings.Parsing.RebelParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Axis Club', 'MusicListings.Parsing.AxisClubParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Baby G', 'MusicListings.Parsing.BabyGParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Concert Hall', 'MusicListings.Parsing.ConcertHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Garrison', 'MusicListings.Parsing.TheGarrisonParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Monarch Tavern', 'MusicListings.Parsing.TheMonarchTavernParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Opera House', 'MusicListings.Parsing.TheOperaHouseParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Phoenix', 'MusicListings.Parsing.ThePhoenixParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Rex', 'MusicListings.Parsing.TheRexParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Velvet Underground', 'MusicListings.Parsing.VelvetUndergroundParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('El Mocambo', 'MusicListings.Parsing.ElMocamboParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Pilot', 'MusicListings.Parsing.PilotParser', false)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Jazz Bistro', 'MusicListings.Parsing.JazzBistroParser', false)"
  end

  def down do
    execute "DELETE FROM venues"
  end
end
