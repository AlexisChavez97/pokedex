# frozen_string_literal: true

module Pokedex
  class CLI
    include Dry::Monads[:result, :try]
    attr_reader :scraper, :pokemon_fetcher, :input_handler, :display

    def initialize(scraper: WebCrawler.new)
      @scraper = scraper
      @input_handler = InputHandler.new
      @display = Display.new
      @pokemon_fetcher = PokemonFetcher.new(scraper)
    end

    def start
      initialize_pokedex
      main_loop
    ensure
      scraper.stop_fetching
    end

    private
      def initialize_pokedex
        display.show_initialization_message
        fetch_pokemon_index
        scraper.queue_and_fetch_all_pokemon_info
      end

      def fetch_pokemon_index
        use_proxy = false
        loop do
          result = scraper.fetch_and_save_pokemon_index(use_proxy:)
          break if result.success?

          display.show_error(result.failure)
          use_proxy = true
          sleep(10)
        end
      end

      def main_loop
        loop do
          input = input_handler.get_pokemon_name
          break if input == "exit"

          results = Pokemon.search(input.tr(" ", "-"))
          if results.empty?
            display.show_no_results(input)
            next
          end

          display.show_search_results(results)
          selected_pokemon = input_handler.get_pokemon_selection(results)
          next unless selected_pokemon

          pokemon_fetcher.fetch_and_display(selected_pokemon)
        end

        display.show_goodbye_message
      end
  end
end
