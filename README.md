# MusicListings

Source code for [https://torontomusiclistings.com](https://torontomusiclistings.com), a music listings aggregator for the Toronto area
written in [Elixir](https://elixir-lang.org/) and [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/welcome.html).

Events are populated via a nightly [Oban](https://github.com/oban-bg/oban) job.

## Running the app locally
- Copy `.envrc_template` to `.envrc` and update / source the required enviroment
variables.
  - Environment variables:
    - `ADMIN_EMAIL` - the email address the application will send communications to.  The application sends an email summary of the nightly event population runs and also when an event is submitted via the UI.  In development these emails will not be sent but instead available at [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox).  See [http://localhost:4000/dev/gallery](http://localhost:4000/dev/gallery) for a preview of the emails.
    - `PULL_DATA_FROM_WWW` - if true will scrape events from the web, when false will use the local files located in `test/data`.
- Run the server (`iex -S mix phx.server`).  Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
- Events are populated via an Oban Job at 7am UTC.
- To manually populate the events, run the following from the IEx terminal: `MusicListings.Workers.DataRetrievalWorker.perform(%{})`.

## Event population
The code that performs event parsing / population for individual venues is located in `lib/music_listings/parsing/venue_parsers`.  Each venue has a parser and parsers implement the `lib/music_listings/parsing/venue_parser.ex` behaviour.

Event population is initiated via the `lib/music_listings/workers/data_retrieval_worker.ex` Oban job.  The Oban job in turn hands off the population of events from individual venues to `lib/music_listings/crawler.ex`.  This module performs retrieval, parsing and storage of events.

### Tracking events for a new venue
In order to track events for a new venue, a new parser for the venue needs to be created at `lib/music_listings/parsing/venue_parsers`.  The venue also needs to be added to the `venues` database table.  Example data files should be added to `test/data` and a test file for the new parser should be added to `test/music_listings/parsing/venue_parsers`.
