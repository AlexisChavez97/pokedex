# frozen_string_literal: true

module Pokedex
  class CLI
    attr_reader :scraper
    
    def initialize(scraper: Pokedex::Scraper.new)
      @scraper = scraper
    end

    def start
      result = scraper.fetch_and_save_pokemon_index
      if result.success?
        scraper.queue_and_fetch_all_pokemon_info
      else
        puts "Failed to fetch and save Pokemon index. Please try again later."
        return
      end

      loop do
        puts "\nEnter a Pokémon name to search (or type 'exit' to quit):"
        input = gets.chomp.downcase
        break if input == 'exit'

        results = Pokemon.search(input)
        if results.empty?
          puts "No results found for '#{input}'."
          next
        end

        display_search_results(results)
        handle_user_selection(results)
      end

      puts "Goodbye!"
    end

    private
      def display_search_results(results)
        puts "Found #{results.length} result(s):"
        results.each_with_index do |pokemon, index|
          puts "#{index + 1}. #{pokemon.name} (#{pokemon.pokedex_number})"
        end
      end

      def handle_user_selection(results)
        puts "Enter the number of the Pokémon you want to see details for:"
        selection = gets.chomp.downcase

        if selection.to_i.between?(1, results.length)
          fetch_and_display_pokemon(results[selection.to_i - 1])
        else
          puts "Invalid selection. Please try again."
        end
      end

      def fetch_and_display_pokemon(pokemon)
        display_result(pokemon)
        
        if pokemon.info_is_empty?
          puts "Note: Detailed information for #{pokemon.name} is currently being fetched."
          puts "Please check again in a few moments for complete information."
          scraper.priority_enqueue(pokemon)
        end
      end

      def display_result(pokemon)
        puts "\nPokémon: #{pokemon.name} (#{pokemon.pokedex_number})"
        puts "Types: #{pokemon.types.join(', ')}"
        puts "Abilities: #{pokemon.abilities.join(', ')}"
        puts "Stats: #{pokemon.stats}"
        puts "-------------------------"
      end
  end
end
