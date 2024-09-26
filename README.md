# Pokedex CLI

## Requirements

- Ruby 3.2.2

## Setup

1. Install the required Ruby version:
   ```
   rbenv install 3.2.2
   ```
   or
   ```
   rvm install 3.2.2
   ```

2. Install dependencies:
   ```
   bundle install
   ```

3. Setup the DB
   ```
   createdb pokedex_db
   ```

4. Run the application:
   ```
   bin/pokedex
   ```

## Docs

### Core Components

#### Pokedex::CLI

The main interface for user interaction. Key functionalities:
- Initializes the Pokedex by fetching and saving the Pokemon index from https://pokemon.com/us/pokedex/.
- Manages the main loop for user input and Pokemon searches.
- Displays Pokemon information to the user.

#### Pokedex::WebCrawler

Responsible for fetching and managing Pokemon data. Main features:
- Fetches and saves the Pokemon index.
- Manages a queue system for fetching detailed Pokemon information.
- Handles priority requests for specific Pokemon.

#### PokemonExternal::Client

Manages external requests to the Pokemon website. Key features:
- Simulates human-like behavior to avoid detection.
- Handles retries and proxy usage for failed requests.
- Fetches HTML content from the Pokemon website.

#### Pokedex::Parser

Parses HTML content from the Pokemon website. Main functionality:
- Extracts Pokemon index information.
- Parses detailed Pokemon information from individual pages.

#### Pokedex::PokemonFetcher

Handles the fetching and display of individual Pokemon. Key features:
- Displays Pokemon details to the user.
- Initiates priority fetching for Pokemon requested by the user with missing information.

#### ApiRequest

Provides caching mechanism for API requests. Main features:
- Caches responses based on request URLs.
- Implements cache policies to determine when to fetch fresh data.

### Additional Components

### Key Concepts

- The application uses a queue system to manage parallel fetching of Pokemon details.
- Proxy servers are utilized when the main Pokemon website starts blocking requests.
- Human-like behavior simulation is implemented to avoid detection by the Pokemon website.

For detailed implementation of these components, refer to the respective files in the `lib` directory.