# frozen_string_literal: true

require_relative "../test_helper"

class PokemonTest < Minitest::Test
  def setup
    super
    @subject = Models::Pokemon.new(name: "Pikachu", pokedex_number: 25)
  end

  def test_it_saves_pokemon
    assert_equal 0, Models::Pokemon.all.count

    @subject.save
    assert_equal 1, Models::Pokemon.all.count

    saved_pokemon = Models::Pokemon.all.first

    assert_equal "Pikachu", saved_pokemon.name
    assert_equal 25, saved_pokemon.pokedex_number
  end

  def test_it_finds_pokemon_by_name
    @subject.save
    found_pokemons = Models::Pokemon.find_by_name("Pika")

    assert_equal 1, found_pokemons.length
    assert_equal "Pikachu", found_pokemons.first.name
  end
end