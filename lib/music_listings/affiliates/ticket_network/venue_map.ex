defmodule MusicListings.Affiliates.TicketNetwork.VenueMap do
  @moduledoc """
  Maps a TicketNetwork venue name (the catalog's `Labels` field) onto one of our
  venues.

  TicketNetwork's venue naming is stable and self-consistent - across the Toronto
  concerts catalog every distinct label carries exactly one address - so a
  hand-curated map is safe here, and far more reliable than fuzzy-matching venue
  names or addresses (postal codes disagree with ours on about a third of the
  venues, e.g. TicketNetwork has Lee's Palace at M5S 1Y4 where we have M5S 1Y5).

  The map keys on `parser_module_name` rather than venue id because ids are
  assigned per environment, so an id written here would point at a different
  venue in dev than in prod - the same reasoning behind
  `MusicListings.Venues.fetch_venue_by_parser_module_name/1`.

  The map is many-to-one: TicketNetwork lists some of our venues as separate
  rooms (both Great Hall rooms are one venue to us).
  """

  @venue_map %{
    "Adelaide Hall - Toronto" => "AdelaideHallParser",
    "Annabel's Music Hall" => "AnnabelsParser",
    "Bovine Sex Club" => "BovineParser",
    "Cabana Pool Bar" => "CabanaParser",
    "Coca-Cola Coliseum" => "CocaColaColiseumParser",
    "Coda - Toronto" => "CodaParser",
    "Concert Stage At Harbourfront Centre" => "HarbourfrontCentreParser",
    "DPRTMNT" => "DprtmntParser",
    "Danforth Music Hall Theatre" => "DanforthMusicHallParser",
    "Hard Luck Bar" => "HardLuckParser",
    "History - Toronto" => "HistoryParser",
    "Horseshoe Tavern" => "HorseshoeTavernParser",
    "Hugh's Room Live" => "HughsRoomParser",
    "Jane Mallett Theatre" => "StLawrenceArtsCentreParser",
    "Lees Palace" => "LeesPalaceParser",
    # Both Great Hall rooms are the one venue to us.  Note we also have a
    # separate "Longboat Hall" venue row with no parser and no events - it must
    # not be used here, the shows are stored under The Great Hall.
    "Longboat Hall At The Great Hall" => "GreatHallParser",
    "Main Hall At The Great Hall" => "GreatHallParser",
    "Massey Hall At Allied Music Centre" => "MasseyHallParser",
    "Meridian Hall" => "MeridianHallParser",
    "Monarch Tavern" => "MonarchTavernParser",
    "Phoenix Concert Theatre" => "PhoenixParser",
    "Queen Elizabeth Theatre - Toronto" => "QueenElizabthTheatreParser",
    # The venue was renamed from Budweiser Stage; the parser module was not.
    "RBC Amphitheatre" => "BudweiserStageParser",
    "Rebel - Toronto" => "RebelParser",
    "Rogers Centre" => "RogersCentreParser",
    "Rogers Stadium At Downsview Airport" => "RogersStadiumParser",
    "Roy Thomson Hall" => "RoyThomsonHallParser",
    "Scotiabank Arena" => "ScotiabankParser",
    "Sneaky Dee's" => "SneakyDeesParser",
    "TD Music Hall At Allied Music Centre" => "TDMusicHallParser",
    "The Baby G" => "BabyGParser",
    "The Concert Hall at Toronto Masonic Temple" => "ConcertHallParser",
    "The Dance Cave - Ontario" => "DanceCaveParser",
    "The Drake Hotel" => "DrakeUndergroundParser",
    "The Garrison" => "GarrisonParser",
    "The Mod Club" => "AxisClubParser",
    "The Opera House - Toronto" => "OperaHouseParser",
    "The Rivoli - Toronto" => "RivoliParser",
    "The Sound Garage At Blood Brothers" => "SoundGarageParser",
    "The Theatre at Great Canadian Casino Resort" => "GreatCanadianCasinoParser",
    "Under The Neon Palms at The El Mocambo" => "ElMocamboParser"
  }

  # Venues TicketNetwork covers that we deliberately do not, listed so a future
  # reader can tell "not mapped yet" from "not ours".  Mostly Mirvish-style
  # theatre and comedy rooms.  Koerner Hall is the one real music venue here and
  # is the best candidate if we ever add another parser.
  # @untracked [
  #   "CAA Theatre",
  #   "Comedy Bar Danforth",
  #   "East End United Church",
  #   "Ed Mirvish Theatre",
  #   "Elgin Theatre At Elgin & Winter Garden Theatre Centre",
  #   "Fort York National Historic Site",
  #   "Koerner Hall",
  #   "Lithuanian House",
  #   "Princess Of Wales Theatre",
  #   "South River in the Portlands",
  #   "The Royal Theatre - Toronto",
  #   "Winter Garden Theatre - Toronto"
  # ]

  @doc """
  The parser module name for a TicketNetwork venue label, or `nil` if we don't
  track that venue.
  """
  @spec parser_module_name(String.t() | nil) :: String.t() | nil
  def parser_module_name(nil), do: nil
  def parser_module_name(venue_label), do: Map.get(@venue_map, venue_label)

  @doc """
  Every parser module name referenced by the map.
  """
  @spec parser_module_names :: [String.t()]
  def parser_module_names, do: @venue_map |> Map.values() |> Enum.uniq()
end
