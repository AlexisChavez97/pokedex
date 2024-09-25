# frozen_string_literal: true

module Pokedex
  class WebCrawler
    include Dry::Monads[:result, :try]

    attr_reader :client, :parser, :queue

    def initialize(client: randomize_client, parser: Parser.new)
      @client = client
      @parser = parser
      @queue = QueueManager.new
      @fetch_thread = nil
      @stop_fetching = false
    end

    def fetch_and_save_pokemon_index(use_proxy: false)
      return Success(:populated) if pokedex_populated?

      client.get(resource: "pokemon_index", use_proxy:)
            .bind { |html| parser.parse_pokemon_index(html) }
            .bind { |pokemon_list| save_pokemon_index(pokemon_list) }
            .fmap { |_| :populated }
            .or { |error| Failure("Failed to fetch pokemons: #{error}") }
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

    def stop_fetching
      @stop_fetching = true
      @fetch_thread&.join(5)
      @fetch_thread&.kill if @fetch_thread&.alive?
      @fetch_thread = nil
    end

    private
      def fetch_all_pokemon_info
        @stop_fetching = false
        @fetch_thread = Thread.new do
          until @stop_fetching
            pokemon = queue.next_in_queue
            break unless pokemon
            fetch_and_update_pokemon_info(pokemon)
            sleep(10)
          end
        end
      end

      def fetch_and_update_pokemon_info(pokemon)
        return Success(pokemon) unless pokemon.info_is_empty?

        use_proxy = [false, true].sample

        client.get(resource: "pokemon_info", use_proxy:, name: pokemon.name)
              .bind { |html| parser.parse_pokemon_info(html) }
              .bind { |pokemon_info| update_pokemon_info(pokemon, pokemon_info) }
              .or { |error| queue.enqueue_priority(pokemon) }
      end

      def save_pokemon_index(pokemon_list)
        return Failure("No pokemon found") unless pokemon_list.any?

        Try do
          Pokemon.bulk_insert(pokemon_list)
          Pokemon.all
        end.to_result
      end

      def update_pokemon_info(pokemon, info)
        return Failure("No info found") if info.values.any?(&:empty?)

        Try do
          pokemon.update(info)
          pokemon
        end.to_result
      end

      def pokedex_populated?
        Pokemon.all.size > 0
      end

      def randomize_client
        [PokemonExternal::SeleniumClient.new, PokemonExternal::PlaywrightClient.new].sample
      end
  end
end
