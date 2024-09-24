# frozen_string_literal: true

require_relative "test_helper"

class PokeScraperTest < Minitest::Test
  def setup
    super
    @client = Minitest::Mock.new
    @parser = Minitest::Mock.new
    @subject = PokeScraper.new(client: @client, parser: @parser)
  end

  def test_call_when_pokedex_is_empty
    Models::Pokemon.delete_all

    mock_index_response = "mock index HTML"
    mock_info_response = "mock info HTML"
    mock_parsed_index = [{ name: "Bulbasaur", pokedex_number: 1 }]
    mock_parsed_info = {
      types: ["Grass", "Poison"],
      abilities: ["Overgrow", "Chlorophyll"],
      stats: { hp: 45, attack: 49, defense: 49, special_attack: 65, special_defense: 65, speed: 45 }
    }

    @client.expect(:get, Success(mock_index_response), resource: "pokemon_index")
    @client.expect(:get, Success(mock_info_response), resource: "pokemon_info", name: "Bulbasaur" )
    @parser.expect(:parse_pokemon_index, Success(mock_parsed_index), [mock_index_response])
    @parser.expect(:parse_pokemon_info, Success(mock_parsed_info), [mock_info_response])

    result = @subject.call

    assert_instance_of Dry::Monads::Success, result
    assert_equal 1, Models::Pokemon.all.count
    pokemon = Models::Pokemon.find_by_name("Bulbasaur").first
    assert_equal "Bulbasaur", pokemon.name
    assert_equal 1, pokemon.pokedex_number
    assert_equal ["Grass", "Poison"], pokemon.types
    assert_equal ["Overgrow", "Chlorophyll"], pokemon.abilities
    assert_equal({ hp: 45, attack: 49, defense: 49, special_attack: 65, special_defense: 65, speed: 45 }, pokemon.stats)

    @client.verify
    @parser.verify
  end

  # def test_call_when_pokedex_is_populated
  #   Models::Pokemon.create(name: "Bulbasaur", pokedex_number: 1)

  #   mock_info_response = "mock info HTML"
  #   mock_parsed_info = {
  #     types: ["Grass", "Poison"],
  #     abilities: ["Overgrow", "Chlorophyll"],
  #     stats: { hp: 45, attack: 49, defense: 49, special_attack: 65, special_defense: 65, speed: 45 }
  #   }

  #   @client.expect(:get, Success(mock_info_response), [{ resource: "pokemon_info", name: "Bulbasaur" }])
  #   @parser.expect(:parse_pokemon_info, Success(mock_parsed_info), [mock_info_response])

  #   result = @subject.call

  #   assert_instance_of Dry::Monads::Success, result
  #   pokemon = Models::Pokemon.find_by(name: "Bulbasaur")
  #   assert_equal ["Grass", "Poison"], pokemon.types
  #   assert_equal ["Overgrow", "Chlorophyll"], pokemon.abilities
  #   assert_equal({ hp: 45, attack: 49, defense: 49, special_attack: 65, special_defense: 65, speed: 45 }, pokemon.stats)

  #   @client.verify
  #   @parser.verify
  # end

  # def test_call_with_network_error
  #   @client.expect(:get, Failure("Network error"), [{ resource: "pokemon_index" }])

  #   result = @subject.call

  #   assert_instance_of Dry::Monads::Failure, result
  #   assert_equal "Scraping failed: Network error", result.failure

  #   @client.verify
  # end

  # def test_call_with_unknown_resource
  #   @client.expect(:get, Failure("Unknown resource"), [{ resource: "pokemon_index" }])

  #   result = @subject.call

  #   assert_instance_of Dry::Monads::Failure, result
  #   assert_equal "Scraping failed: Unknown resource", result.failure

  #   @client.verify
  # end
end