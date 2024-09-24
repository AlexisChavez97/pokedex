# frozen_string_literal: true
require "pry"

class PokeScraper
  include Dry::Monads[:result, :try]
  
  attr_reader :client, :parser
  
  def initialize(client:, parser:)
    @client = client
    @parser = parser
  end

  def call
    ensure_pokemon_index
      .bind { fetch_and_update_pokemon_info }
      .or { |error| Failure("Scraping failed: #{error}") }
  end

  private
    def ensure_pokemon_index
      if pokedex_populated?
        Success(Models::Pokemon.all)
      else
        fetch_and_save_pokemon_index
      end
    end

    def fetch_and_save_pokemon_index
      client.get(resource: "pokemon_index")
        .bind { |html| parser.parse_pokemon_index(html) }
        .bind { |pokemon_list| save_pokemon_index(pokemon_list) }
    end

    def save_pokemon_index(pokemon_list)
      Try do
        pokemon_list.map do |pokemon_info|
          Models::Pokemon.create(pokemon_info)
        end
      end.to_result
    end

    def fetch_and_update_pokemon_info
      Models::Pokemon.all.map do |pokemon|
        fetch_and_update_pokemon_detail(pokemon)
      end
      Success("Pokemon info updated successfully")
    end

    def fetch_and_update_pokemon_detail(pokemon)
      return Success(pokemon) unless pokemon.info_is_empty?

      client.get(resource: "pokemon_info", name: pokemon.name)
        .bind { |html| parser.parse_pokemon_info(html) }
        .bind { |info| update_pokemon_info(pokemon, info) }
        .or { |error| Failure("Failed to update info for #{pokemon.name}: #{error}") }
    end

    def update_pokemon_info(pokemon, info)
      Try do
        pokemon.update(info)
        pokemon
      end.to_result
    end

    def pokedex_populated?
      Models::Pokemon.all.count > 0
    end
end
