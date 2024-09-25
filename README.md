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

### CLI

- When the CLI starts, it will check if the Pokémon index is already saved in the database. If not, it will fetch the data from the Pokémon site and save it to the database.
- After the Pokémon index is saved, a thread is started to fetch the Pokémon details from the Pokémon site in parallel as the CLI prompts the user to enter a Pokémon name to search for.
- When the user enters a Pokémon name, the CLI searches for the Pokémon in the database. If the Pokémon is found, its details are displayed. If the details are missing, the CLI will prioritize fetching the missing details for the requested Pokémon by using a queue system.

### Web Crawler

- The web crawler is responsible for requesting the Pokémon index and the Pokémon details from the Pokémon site client and saving the data to the database.
- It calls the Selenium Client to fetch the Pokémon index and the Pokémon details.
- It uses a queue system to fetch the Pokémon details in parallel.
- It then sends the HTML content to the Parser to save the data to the database.

### Pokemon External Client

- Responsible for assigning the requests to the correct Pokémon resource and simulating human behavior to avoid being blocked by the site.

### Parser

- Responsible for parsing the HTML content of the Pokémon site.

### Api Request

- Api Request acts as a caching mechanism that saves the request url as the key and the response as the value.
- If another request is made for the same url, it will return the cached response if the cache policy is valid.
- If the cache policy is expired, it will allow the request to proceed and then cache the response.


If the app realizes that the Pokémon site is blocking the requests, it will enable the use of proxies to attempt to fetch the Pokémon details.
