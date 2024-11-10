# MusicListings

Source code for [https://torontomusiclistings.com](https://torontomusiclistings.com), a music listings aggregator for the Toronto area
written in [Elixir](https://elixir-lang.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/welcome.html).

Events are populated via a nightly [Oban](https://github.com/oban-bg/oban) job.

## Running the app locally
- Copy `.envrc_template` to `.envrc` and update / source the required enviroment
variables.
  - Environment variables:
    - `ADMIN_EMAIL` - the email address the application will send communications to.  The application sends an email summary of the nightly event population runs and also when an event is submitted via the UI.  In development these emails will not be sent but instead be available at [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox).  See [http://localhost:4000/dev/gallery](http://localhost:4000/dev/gallery) for a preview of the emails.
    - `PULL_DATA_FROM_WWW` - if true will scrape events from the web, when false will use the local files located in `test/data`.
- Run the server (`iex -S mix phx.server`).  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
- Events are populated via an Oban Job at 7am UTC.
- To manually populate the events, run the following from the IEx terminal: `MusicListings.Workers.DataRetrievalWorker.perform(%{})`.
- To run the tests: `mix test`.

## Admin functionality
Currently there is very limited admin functionality available (just the ability to delete events).  The Admin functionality is only available when logged in to the application.  

User management is handled by [Phx Gen Auth](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html).  Much of the UI component of `Phx Gen Auth` has been removed as there is no need for users to create accounts etc.  So the admin user needs to be created via `iex`, i.e. open an `iex` session and run the following:
```
MusicListings.Accounts.register_user(%{email: "bob_admin@example.com", password: "some_password"})
```

Now you can login at `/users/log_in`.  When logged in, delete links will be available on both the `/events` and `/events/venue/xx` pages.

## HTTP Client config
The http client is configurable via the following setting in `config/config.exs`:
```
config :music_listings, :http_client, MusicListings.HttpClient.HTTPoison
```
Modules currently exist for [Req](https://github.com/wojtekmach/req) and [HTTPoison](https://github.com/edgurgel/httpoison) (see `lib/music_listings/http_client/req.ex` and `lib/music_listings/http_client/httpoison.ex`).

To add a new http client add a module at `lib/music_listings/http_client/` and implement the `lib/music_listings/http_client.ex` behaviour.

Initially the http client was not configurable but I ran into some issues with  `brotli` decoding and `Req` (the underlying brotli module was failing on the decoding of some sites) so for now have swapped it out with `HTTPoison`.

## UI
The UI is a standard Phoenix LiveView application.

Venue filtering persistence is accomplished via local storage, see the `VenueFilter` hook in `assets/js/app.js` which gets called from `lib/music_listings_web/live/event_live/index.ex`.

## Crawling / Event population
Event population is initiated via the `lib/music_listings/workers/data_retrieval_worker.ex` Oban job.  The Oban job in turn hands off the population of events to `lib/music_listings/crawler.ex`.  This module performs retrieval, parsing and storage of events.

Once event population has concluded an email is sent to the configured `ADMIN_EMAIL` with details of the crawl.  Results are also captured in the `crawl_summaries`, `venue_crawl_summaries` and `crawl_errors` database tables.

### Parsing modules
The code that performs event parsing for individual venues is located in `lib/music_listings/parsing/venue_parsers`.  Each venue has a parser and parsers implement the `lib/music_listings/parsing/venue_parser.ex` behaviour.

Any errors encountered during parsing will be inserted into the `crawl_errors` database table and included in the aforementioned crawl results email.

### Adding a new venue
In order to track events for a new venue, a new parser for the venue needs to be created at `lib/music_listings/parsing/venue_parsers`.  The venue also needs to be added to the `venues` database table.  Example data files should be added to `test/data` and a test file for the new parser should be added to `test/music_listings/parsing/venue_parsers`.
