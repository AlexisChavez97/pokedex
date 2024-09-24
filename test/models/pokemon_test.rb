# frozen_string_literal: true
require "pry"
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

  def test_it_updates_pokemon_with_new_info
    @subject.save
    @subject.update(types: ["Electric", "Steel"], abilities: ["Static", "Lightning Rod"],
                    stats: { hp: 100, attack: 100, defense: 100, special_attack: 100, special_defense: 100, speed: 100 })

    found_pokemon = Models::Pokemon.find_by_name("Pikachu").first

    assert_equal "Pikachu", found_pokemon.name
    assert_equal 25, found_pokemon.pokedex_number
    assert_equal ["Electric", "Steel"], found_pokemon.types
    assert_equal ["Static", "Lightning Rod"], found_pokemon.abilities
    assert_equal 100, found_pokemon.stats[:hp]
    assert_equal 100, found_pokemon.stats[:attack]
    assert_equal 100, found_pokemon.stats[:defense]
    assert_equal 100, found_pokemon.stats[:special_attack]
    assert_equal 100, found_pokemon.stats[:special_defense]
    assert_equal 100, found_pokemon.stats[:speed]
  end
end