# frozen_string_literal: true

class PokeScraper
  include Dry::Monads[:result]
  
  attr_reader :client, :parser, :repository
  
  def initialize(client:, parser:, repository:)
    @client = client
    @parser = parser
    @repository = repository
  end

  def scrape_and_save
    client.get(resource: "pokemon_index")
           .bind { |html| parser.parse_pokemon_index(html) }
           .bind { |pokemon_list| maybe_save_pokemon_index(pokemon_list) }
           .or { |error| puts "Error: #{error}" }
  end

  private
    def maybe_save_pokemon_index(pokemon_list)
      if pokedex_populated?
        update_pokemon_details(pokemon_list)
      else
        save_pokemon_index(pokemon_list)
      end
    end

    def update_pokemon_details(pokemon_list)
      pokemon_list.each do |pokemon|
        client.get(resource: "pokemon_details", name: pokemon[:name])
              .bind { |html| parser.parse_pokemon_details(html) }
              .bind { |details| pokemon.merge!(details) }
              .or { |error| puts "Failed to fetch details for #{pokemon[:name]}: #{error}" }
      end

      repository.save_all(pokemon_list)
      Success()
    end

    def save_pokemon_index(pokemon_list)
      if repository.save_all(pokemon_list)
        Success("The pokedex has been updated!")
      else
        Failure("Failed to save Pokémon index")
      end
    end

    def pokedex_populated?
      repository.db[:pokemons].any?
    end
end