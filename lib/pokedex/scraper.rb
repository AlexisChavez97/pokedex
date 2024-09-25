# frozen_string_literal: true

require "pry"

module Pokedex
  class Scraper
    include Dry::Monads[:result, :try]

    attr_reader :client, :parser, :queue

    def initialize(client: PokemonExternal::SeleniumClient.new, parser: Pokedex::Parser.new)
      @client = client
      @parser = parser
      @queue = QueueManager.new
    end

    def fetch_and_save_pokemon_index
      return Success(:populated) if pokedex_populated?

      client.get(resource: "pokemon_index")
            .bind { |html| parser.parse_pokemon_index(html) }
            .bind { |pokemon_list| save_pokemon_index(pokemon_list) }
            .fmap { |_| :populated }
            .or { |error| Failure("Failed to fetch and pokemons: #{error}") }
    end

    def queue_and_fetch_all_pokemon_info
      queue.enqueue_all(Pokemon.all)
      fetch_all_pokemon_info
    end

    def priority_enqueue(pokemon)
      return Success(pokemon) unless pokemon.info_is_empty?

      queue.enqueue_priority(pokemon)

      Success(pokemon)
    end

    private
      def fetch_all_pokemon_info
        Thread.new do
          while pokemon = queue.next_in_queue
            fetch_and_update_pokemon_info(pokemon)
          end
        end
      end

      def fetch_and_update_pokemon_info(pokemon)
        return Success(pokemon) unless pokemon.info_is_empty?

        client.get(resource: "pokemon_info", name: pokemon.name)
              .bind { |html| parser.parse_pokemon_info(html) }
              .bind { |pokemon_info| update_pokemon_info(pokemon, pokemon_info) }
              .or { |error| puts "Failed to fetch and update pokemon info: #{error}" }
      end

      def save_pokemon_index(pokemon_list)
        Try do
          Pokemon.bulk_insert(pokemon_list)
          Pokemon.all
        end.to_result
      end

      def update_pokemon_info(pokemon, info)
        Try do
          pokemon.update(info)
          pokemon
        end.to_result
      end

      def pokedex_populated?
        Pokemon.all.size > 0
      end
  end
end
