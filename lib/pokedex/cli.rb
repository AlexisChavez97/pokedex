# frozen_string_literal: true

module Pokedex
  class CLI
    include Dry::Monads[:result, :try]
    attr_reader :scraper

    def initialize(scraper: WebCrawler.new)
      @scraper = scraper
    end

    def start
      puts "Initializing Pokedex..."
      puts "Fetching and saving Pokemon..."
      use_proxy = false

      loop do
        result = scraper.fetch_and_save_pokemon_index(use_proxy:)

        case result
        when Success(:populated)
          puts "Pokémon index successfully fetched and saved."
          scraper.queue_and_fetch_all_pokemon_info
          break
        when Failure
          puts result.failure
          use_proxy = true
        end
      end

      main_loop
    ensure
      scraper.stop_fetching
    end

    def main_loop
      loop do
        puts "\nEnter a Pokémon name to search (or type 'exit' to quit):"
        input = gets.chomp.downcase
        break if input == "exit"

        results = Pokemon.search(input.tr(" ", "-"))
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
          puts "#{index + 1}. #{pokemon.humanized_name} (#{pokemon.pokedex_number})"
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

        return unless pokemon.info_is_empty?

        puts "Note: Detailed information for #{pokemon.name} is currently being fetched."
        puts "Please check again in a few moments for complete information."
        scraper.priority_enqueue(pokemon)
      end

      def display_result(pokemon)
        puts "\nPokémon: #{pokemon.humanized_name} (#{pokemon.pokedex_number})"
        puts "Types: #{pokemon.types.join(', ')}"
        puts "Abilities: #{pokemon.abilities.join(', ')}"
        puts ""
        display_stats(pokemon.stats)
      end

      def display_stats(stats)
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
