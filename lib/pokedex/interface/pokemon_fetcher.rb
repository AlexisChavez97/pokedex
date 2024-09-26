# frozen_string_literal: true

module Pokedex
  class PokemonFetcher
    attr_reader :scraper, :display

    def initialize(scraper)
      @scraper = scraper
      @display = Display.new
    end

    def fetch_and_display(pokemon)
      display.show_pokemon_details(pokemon)

      return unless pokemon.info_is_empty?

      display.show_fetching_message(pokemon.name)
      scraper.priority_enqueue(pokemon)
    end
  end
end
