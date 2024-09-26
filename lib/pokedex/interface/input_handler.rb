# frozen_string_literal: true

module Pokedex
  class InputHandler
    def get_pokemon_name
      puts "\nEnter a Pokémon name to search (or type 'exit' to quit):"
      gets.chomp.downcase
    end

    def get_pokemon_selection(results)
      puts "Enter the number of the Pokémon you want to see details for:"
      selection = gets.chomp.to_i
      if selection.between?(1, results.length)
        results[selection - 1]
      else
        puts "Invalid selection. Please try again."
        nil
      end
    end
  end
end
