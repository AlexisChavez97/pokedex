# frozen_string_literal: true

class PokemonCLI
  attr_reader :repository, :scraper
  
  def initialize(repository: Pokedex.new, scraper: PokemonScraper.new)
    @repository = repository
    @scraper = scraper
  end

  def start
    scraper.scrape_and_save

    loop do
      puts "\nEnter a Pokémon name to search (or type 'exit' to quit):"
      input = gets.chomp.downcase
      break if input == 'exit'

      results = repository.find_by_name(input)
      if results.any?
        display_results(results)
      else
        puts "No Pokémon found with the name '#{input}'."
      end
    end

    puts "Goodbye!"
  end

  private

  def display_results(results)
    results.each do |pokemon|
      puts "Pokémon: #{pokemon[:name]} (#{pokemon[:pokedex_number]})"
      puts "Types: #{pokemon[:types]}"
      puts "Abilities: #{pokemon[:abilities]}"
      puts "Height: #{pokemon[:height]}m, Weight: #{pokemon[:weight]}kg"
      puts "Stats: HP: #{pokemon[:hp]}, Attack: #{pokemon[:attack]}, Defense: #{pokemon[:defense]}"
      puts "Special Attack: #{pokemon[:special_attack]}, Special Defense: #{pokemon[:special_defense]}, Speed: #{pokemon[:speed]}"
      puts "-------------------------"
    end
  end
end