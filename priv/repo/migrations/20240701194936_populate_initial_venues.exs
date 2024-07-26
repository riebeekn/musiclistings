defmodule MusicListings.Repo.Migrations.PopulateInitialVenues do
  use Ecto.Migration

  def up do
    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Budweiser Stage', 'BudweiserStageParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Cameron House', 'CameronHouseParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Coca Cola Coliseum', 'CocaColaColiseumParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('CODA', 'CodaParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Danforth Music Hall', 'DanforthMusicHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Drake Underground', 'DrakeUndergroundParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('History', 'HistoryParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Horseshoe Tavern', 'HorseshoeTavernParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Lee''s Palace', 'LeesPalaceParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Great Hall', 'GreatHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Massey Hall', 'MasseyHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Roy Thomson Hall', 'RoyThomsonHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('TD Music Hall', 'TDMusicHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Queen Elizabeth Theatre', 'QueenElizabthTheatreParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Rebel', 'RebelParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Axis Club', 'AxisClubParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Baby G', 'BabyGParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Concert Hall', 'ConcertHallParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Garrison', 'GarrisonParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Monarch Tavern', 'MonarchTavernParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Opera House', 'OperaHouseParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Phoenix Concert Theatre', 'PhoenixParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Rex', 'RexParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Velvet Underground', 'VelvetUndergroundParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('El Mocambo', 'ElMocamboParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Pilot', 'PilotParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Jazz Bistro', 'JazzBistroParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('The Dakota Tavern', 'DakotaTavernParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Rogers Centre', 'RogersParser', true)"

    execute "INSERT INTO venues(name, parser_module_name, pull_events) VALUES('Scotiabank Arena', 'ScotiabankParser', true)"
  end

  def down do
    execute "DELETE FROM venues"
  end
end
