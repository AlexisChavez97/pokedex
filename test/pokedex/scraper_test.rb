# frozen_string_literal: true

require_relative "../test_helper"

class Pokedex::ScraperTest < Minitest::Test
  def setup
    super
    @client = Minitest::Mock.new
    @parser = Minitest::Mock.new
    @queue = Minitest::Mock.new
    @subject = Pokedex::Scraper.new(client: @client, parser: @parser)
    @subject.instance_variable_set(:@queue, @queue)
    @mock_index_response = "mock index HTML"
    @mock_info_response = "mock info HTML"
    @mock_parsed_index = [{ name: "bulbasaur", pokedex_number: 1 }]
    @mock_parsed_info = {
      types: %w[Grass Poison],
      abilities: %w[Overgrow Chlorophyll],
      stats: { hp: 45, attack: 49, defense: 49, special_attack: 65, special_defense: 65, speed: 45 }
    }
  end

  def test_fetch_and_save_pokemon_index_when_pokedex_is_empty
    Pokemon.delete_all

    @client.expect(:get, Success(@mock_index_response), resource: "pokemon_index")
    @parser.expect(:parse_pokemon_index, Success(@mock_parsed_index), [@mock_index_response])

    result = @subject.fetch_and_save_pokemon_index

    assert_instance_of Dry::Monads::Success, result
    assert_equal 1, Pokemon.all.count
    pokemon = Pokemon.find_by(name: "bulbasaur")
    assert_equal "bulbasaur", pokemon.name
    assert_equal 1, pokemon.pokedex_number

    @client.verify
    @parser.verify
  end

  def test_fetch_and_save_pokemon_index_when_pokedex_is_populated
    Pokemon.create(name: "bulbasaur", pokedex_number: 1)

    result = @subject.fetch_and_save_pokemon_index

    assert_instance_of Dry::Monads::Success, result
    assert_equal 1, Pokemon.all.count

    assert_raises(MockExpectationError) do
      @client.expect(:get, Success(@mock_index_response), resource: "pokemon_index")
      @client.verify
    end
  end

  def test_queue_and_fetch_all_pokemon_info_is_enqueued
    Pokemon.create(name: "bulbasaur", pokedex_number: 1)
    @queue.expect(:enqueue_all, nil) { |arg| arg.is_a?(Array) && arg.all? { |item| item.is_a?(Pokemon) } }
    @queue.expect(:next_in_queue, nil)

    thread = @subject.queue_and_fetch_all_pokemon_info

    assert_instance_of Thread, thread
    thread.join(0.1)

    @queue.verify
  end

  def test_priority_enqueue_with_empty_info
    pokemon = Pokemon.new(name: "bulbasaur", pokedex_number: 1)
    @queue.expect(:enqueue_priority, nil, [pokemon])

    result = @subject.priority_enqueue(pokemon)

    assert_instance_of Dry::Monads::Success, result
    assert_equal pokemon, result.value!

    @queue.verify
  end

  def test_priority_enqueue_with_populated_info
    pokemon = Pokemon.new(name: "bulbasaur", pokedex_number: 1, types: ["Grass"])

    result = @subject.priority_enqueue(pokemon)

    assert_instance_of Dry::Monads::Success, result
    assert_equal pokemon, result.value!

    assert_raises(MockExpectationError) do
      @queue.expect(:enqueue_priority, nil, [pokemon])
      @queue.verify
    end
  end

  def test_fetch_and_update_pokemon_info_when_empty
    pokemon = Pokemon.new(name: "bulbasaur", pokedex_number: 1)

    @client.expect(:get, Success(@mock_info_response), resource: "pokemon_info", name: "bulbasaur")
    @parser.expect(:parse_pokemon_info, Success(@mock_parsed_info), [@mock_info_response])

    result = @subject.send(:fetch_and_update_pokemon_info, pokemon)

    assert_instance_of Dry::Monads::Success, result

    updated_pokemon = result.value!
    assert_equal @mock_parsed_info[:types], updated_pokemon.types
    assert_equal @mock_parsed_info[:abilities], updated_pokemon.abilities
    assert_equal @mock_parsed_info[:stats], updated_pokemon.stats

    @client.verify
    @parser.verify
  end

  def test_fetch_and_update_pokemon_info_when_populated
    pokemon_attrs = @mock_parsed_info.merge(name: "bulbasaur", pokedex_number: 1)
    pokemon = Pokemon.new(pokemon_attrs)

    result = @subject.send(:fetch_and_update_pokemon_info, pokemon)

    assert_instance_of Dry::Monads::Success, result
    updated_pokemon = result.value!

    assert_equal pokemon, updated_pokemon
    assert_equal @mock_parsed_info[:types], updated_pokemon.types
    assert_equal @mock_parsed_info[:abilities], updated_pokemon.abilities
    assert_equal @mock_parsed_info[:stats], updated_pokemon.stats

    assert_raises(MockExpectationError) do
      @client.expect(:get, Success(@mock_info_response), resource: "pokemon_info", params: { name: "bulbasaur" })
      @parser.expect(:parse_pokemon_info, Success(@mock_parsed_info), [@mock_info_response])
      @client.verify
      @parser.verify
    end
  end
end
