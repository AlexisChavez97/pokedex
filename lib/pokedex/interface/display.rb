# frozen_string_literal: true

module Pokedex
  class Display
    def show_initialization_message
      puts "Initializing Pokedex..."
      puts "Fetching and saving Pokemon..."
      puts "Missing Pokémon data will continue to be fetched in the background."
    end

    def show_error(message)
      puts message
    end

    def show_no_results(input)
      puts "No results found for '#{input}'."
    end

    def show_search_results(results)
      puts "Found #{results.length} result(s):"
      results.each_with_index do |pokemon, index|
        puts "#{index + 1}. #{pokemon.humanized_name} (#{pokemon.pokedex_number})"
      end
    end

    def show_pokemon_details(pokemon)
      puts "\nPokémon: #{pokemon.humanized_name} (#{pokemon.pokedex_number})"
      puts "Types: #{pokemon.types.join(', ')}"
      puts "Abilities: #{pokemon.abilities.join(', ')}"
      puts ""
      show_stats(pokemon.stats)
    end

    def show_fetching_message(pokemon_name)
      puts "Note: Detailed information for #{pokemon_name} is currently being fetched."
      puts "Please check again in a few moments for complete information."
    end

    def show_goodbye_message
      puts "Goodbye!"
    end

    private
      def show_stats(stats)
        max_stat = 15
        bar_length = 20
        stats.each_with_index do |(stat_name, stat_value), index|
          stat_percentage = (stat_value.to_f / max_stat) * 100
          filled_length = (stat_percentage / 100 * bar_length).round
          empty_length = bar_length - filled_length

          bar = "█" * filled_length + "░" * empty_length
          formatted_name = stat_name.to_s.split("_").map(&:capitalize).join(" ").ljust(15)

          puts "#{formatted_name} [#{bar}] #{stat_value}/#{max_stat}"

          puts "" unless index == stats.size - 1
        end
      end
  end
end
