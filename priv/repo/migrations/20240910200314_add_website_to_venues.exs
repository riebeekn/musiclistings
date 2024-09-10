defmodule MusicListings.Repo.Migrations.AddWebsiteToVenues do
  use Ecto.Migration

  def up do
    alter table(:venues) do
      add :website, :string
    end

    execute "UPDATE venues SET website = 'https://www.adelaidehallto.com' WHERE name = 'Adelaide Hall'"

    execute "UPDATE venues SET website = 'https://www.annabelsto.com' WHERE name = 'Annabel''s Music Hall'"

    execute "UPDATE venues SET website = 'https://www.bovinesexclub.com' WHERE name = 'Bovine Sex Club'"

    execute "UPDATE venues SET website = 'https://www.bsmt254.com' WHERE name = 'BSMT 254'"

    execute "UPDATE venues SET website = 'https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events' WHERE name = 'Budweiser Stage'"

    execute "UPDATE venues SET website = 'https://burdockbrewery.com' WHERE name = 'Burdock Music Hall'"

    execute "UPDATE venues SET website = 'https://castroslounge.com' WHERE name = 'Castro''s Lounge'"

    execute "UPDATE venues SET website = 'https://www.theex.com' WHERE name = 'CNE'"

    execute "UPDATE venues SET website = 'https://www.coca-colacoliseum.com' WHERE name = 'Coca Cola Coliseum'"

    execute "UPDATE venues SET website = 'https://www.codatoronto.com' WHERE name = 'CODA'"

    execute "UPDATE venues SET website = 'https://www.thedrake.ca' WHERE name = 'Drake Underground'"

    execute "UPDATE venues SET website = 'https://www.dromtaberna.com' WHERE name = 'Drom Taberna'"

    execute "UPDATE venues SET website = 'https://elmocambo.com' WHERE name = 'El Mocambo'"

    execute "UPDATE venues SET website = 'https://grossmanstavern.com' WHERE name = 'Grossman''s Tavern'"

    execute "UPDATE venues SET website = 'https://thehandlebar.ca' WHERE name = 'Handlebar'"
    execute "UPDATE venues SET website = 'https://www.historytoronto.com' WHERE name = 'History'"
    execute "UPDATE venues SET website = 'https://hughsroomlive.com/' WHERE name = 'Hugh''s Room'"
    execute "UPDATE venues SET website = 'https://jazzbistro.ca' WHERE name = 'Jazz Bistro'"

    execute "UPDATE venues SET website = 'https://www.leespalace.com' WHERE name = 'Lee''s Palace'"

    execute "UPDATE venues SET website = 'https://www.linsmoretavern.com' WHERE name = 'Linsmore Tavern'"

    execute "UPDATE venues SET website = 'https://masseyhall.mhrth.com' WHERE name = 'Massey Hall'"

    execute "UPDATE venues SET website = 'https://www.poetryjazzcafe.com' WHERE name = 'Poetry Jazz Cafe'"

    execute "UPDATE venues SET website = 'https://primalnote.com' WHERE name = 'Primal Note Studios'"

    execute "UPDATE venues SET website = 'https://www.queenelizabeththeatre.ca' WHERE name = 'Queen Elizabeth Theatre'"

    execute "UPDATE venues SET website = 'https://rebeltoronto.com' WHERE name = 'Rebel'"
    execute "UPDATE venues SET website = 'https://www.rivolitoronto.com' WHERE name = 'Rivoli'"

    execute "UPDATE venues SET website = 'https://www.livenation.com/venue/KovZpa3Bbe/rogers-centre-events' WHERE name = 'Rogers Centre'"

    execute "UPDATE venues SET website = 'https://roythomsonhall.mhrth.com' WHERE name = 'Roy Thomson Hall'"

    execute "UPDATE venues SET website = 'https://www.scotiabankarena.com' WHERE name = 'Scotiabank Arena'"

    execute "UPDATE venues SET website = 'https://www.supermarketto.ca' WHERE name = 'Supermarket'"

    execute "UPDATE venues SET website = 'https://tdmusichall.mhrth.com' WHERE name = 'TD Music Hall'"

    execute "UPDATE venues SET website = 'https://theaxisclub.com' WHERE name = 'The Axis Club'"
    execute "UPDATE venues SET website = 'http://thebabyg.com' WHERE name = 'The Baby G'"

    execute "UPDATE venues SET website = 'https://www.thecameron.com/' WHERE name = 'The Cameron House'"

    execute "UPDATE venues SET website = 'https://888yonge.com' WHERE name = 'The Concert Hall'"

    execute "UPDATE venues SET website = 'https://www.dakotatavern.ca' WHERE name = 'The Dakota Tavern'"

    execute "UPDATE venues SET website = 'https://thedanforth.com' WHERE name = 'The Danforth Music Hall'"

    execute "UPDATE venues SET website = 'http://www.garrisontoronto.com' WHERE name = 'The Garrison'"

    execute "UPDATE venues SET website = 'https://thegreathall.ca' WHERE name = 'The Great Hall'"

    execute "UPDATE venues SET website = 'https://www.horseshoetavern.com' WHERE name = 'The Horseshoe Tavern'"

    execute "UPDATE venues SET website = 'https://www.themonarchtavern.com/' WHERE name = 'The Monarch Tavern'"

    execute "UPDATE venues SET website = 'https://theoperahousetoronto.com' WHERE name = 'The Opera House'"

    execute "UPDATE venues SET website = 'https://thephoenixconcerttheatre.com' WHERE name = 'The Phoenix Concert Theatre'"

    execute "UPDATE venues SET website = 'https://www.thepilot.ca' WHERE name = 'The Pilot'"
    execute "UPDATE venues SET website = 'https://www.therex.ca' WHERE name = 'The Rex'"
    execute "UPDATE venues SET website = 'https://therockpile.ca' WHERE name = 'The Rockpile'"
    execute "UPDATE venues SET website = 'https://www.tranzac.org' WHERE name = 'Tranzac'"
    execute "UPDATE venues SET website = 'https://thevelvet.ca' WHERE name = 'Velvet Underground'"
  end

  def down do
    alter table(:venues) do
      remove :website
    end
  end
end
