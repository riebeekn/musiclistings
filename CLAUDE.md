# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **MusicListings**, a Phoenix LiveView application that aggregates music event listings for the Toronto area. The app crawls various venue websites to collect and display upcoming concerts and events at [torontomusiclistings.com](https://torontomusiclistings.com).

## Tech Stack

- **Elixir** ~> 1.14
- **Phoenix Framework** ~> 1.7.14
- **Phoenix LiveView** ~> 1.1
- **PostgreSQL** database with Ecto
- **Tailwind CSS** for styling
- **Oban** for background jobs (though crawling now uses Render Cron)
- **Deployment**: Render (previously Fly.io, with AWS infrastructure also available)

## Common Development Commands

### Setup and Development
```bash
# Install dependencies
mix deps.get

# Setup database (create, migrate, seed)
mix ecto.setup

# Start Phoenix server with IEx
iex -S mix phx.server

# Reset database
mix ecto.reset

# Run migrations
mix ecto.migrate
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/music_listings/parsing/venue_parsers/phoenix_parser_test.exs

# Run with coverage
mix coveralls.html
```

### Code Quality
```bash
# Format code
mix format

# Run linter with strict mode
mix credo --strict

# Run dialyzer for type checking
mix dialyzer

# Full check (format, credo, compile with warnings, dialyzer, docs)
mix check
```

### Assets
```bash
# Build assets for development
mix assets.build

# Deploy assets for production
mix assets.deploy
```

## Architecture Overview

### Core Domain Structure

The application follows a modular architecture with clear separation of concerns:

1. **Web Layer** (`lib/music_listings_web/`)
   - LiveView modules for real-time UI (`live/`)
   - Components for reusable UI elements (`components/`)
   - Router defining all application routes
   - User authentication via phx.gen.auth

2. **Business Logic** (`lib/music_listings/`)
   - **Crawler Module**: Orchestrates web scraping and event storage
   - **Events Context**: Manages event queries and business logic
   - **Venues Context**: Handles venue data and relationships
   - **Parsing System**: Modular venue-specific parsers

3. **Data Layer** (`lib/music_listings_schema/`)
   - Ecto schemas for database entities
   - Events, Venues, CrawlSummaries, SubmittedEvents

### Parsing System Architecture

The parsing system is highly modular with a clear hierarchy:

- **VenueParser behaviour** defines the contract all parsers must implement
- **Base Parsers** (`lib/music_listings/parsing/venue_parsers/base_parsers/`) provide reusable parsing logic for common platforms (LiveNation, SquareSpace, WordPress, etc.)
- **Venue-Specific Parsers** inherit from base parsers or implement custom logic
- Each parser returns a list of `Payload` structs containing parsed event data

### Key Workflows

1. **Event Crawling**:
   - Triggered via Render Cron job (see `lib/music_listings/application.ex`)
   - `Crawler` module fetches data from each venue
   - Venue-specific parsers extract event information
   - Events are stored/updated in database
   - Email summary sent to admin

2. **Event Display**:
   - LiveView pages at `/events` and `/events/venue/:venue_id`
   - Real-time filtering by venue using JavaScript hooks
   - Venue preferences stored in localStorage

3. **Event Submission**:
   - Users can submit events via `/events/new`
   - Admin approval required (accessible when logged in)

## Environment Variables

Key environment variables (set in `.envrc` from `.envrc_template`):
- `ADMIN_EMAIL`: Receives crawl summaries and submission notifications
- `PULL_DATA_FROM_WWW`: `true` for production, `false` to use test data
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY_BASE`: Phoenix secret key
- `TURNSTILE_SITE_KEY` / `TURNSTILE_SECRET_KEY`: Cloudflare Turnstile for spam protection
- `BREVO_API_KEY`: Email service configuration

## Adding New Venues

To add support for a new venue:

1. Create parser at `lib/music_listings/parsing/venue_parsers/[venue_name]_parser.ex`
2. Implement the `VenueParser` behaviour
3. Add venue to database via migration in `priv/repo/migrations/`
4. Add test data in `test/data/[venue_name]/`
5. Create test file at `test/music_listings/parsing/venue_parsers/[venue_name]_parser_test.exs`

## Database Operations

### Common Ecto Commands
```elixir
# In IEx console
alias MusicListings.{Repo, Events, Venues}
alias MusicListingsSchema.{Event, Venue, SubmittedEvent}

# Query examples
Venues.list_venues()
Events.list_events()
Repo.get(Venue, venue_id)

# Manual crawl trigger
MusicListings.Workers.DataRetrievalWorker.perform(%{})
```

### Admin User Creation
```elixir
# Create admin user (in IEx)
MusicListings.Accounts.register_user(%{
  email: "admin@example.com",
  password: "secure_password"
})
```

## Testing Approach

- Comprehensive unit tests for all parsers using local HTML fixtures
- Integration tests for LiveView components
- Factory-based test data generation with ExMachina
- Coverage reporting with ExCoveralls

## Deployment Notes

- Application deploys automatically via GitHub Actions
- Deployment targets controlled by GitHub Action variables:
  - `DEPLOY_TO_RENDER`
  - `DEPLOY_TO_FLY`
  - `DEPLOY_TO_AWS`
- Infrastructure managed via Terraform (`.infrastructure/` directory)
- Uses CloudFlare as reverse proxy

## Important Patterns

1. **Error Handling**: Parse errors are captured in `crawl_errors` table and included in admin emails
2. **Memory Management**: Crawling builds payloads in memory - be mindful of venue count
3. **HTTP Client**: Configurable via `config :music_listings, :http_client`
4. **LiveView Hooks**: Venue filter persistence uses JavaScript hooks in `assets/js/app.js`

## Development Workflow

1. Always run `mix format`, `mix dialyzer` and `mix credo --strict` after all changes have been made and fix any warnings
2. Always run `mix test` after all changes have been made and ensure all the tests pass
