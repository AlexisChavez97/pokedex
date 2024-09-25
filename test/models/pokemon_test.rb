# frozen_string_literal: true

require_relative "../test_helper"

class PokemonTest < Minitest::Test
  def setup
    super
    @subject = Pokemon.new(name: "pikachu", pokedex_number: 25)
  end

  def test_it_validates_presence_of_name
    subject = Pokemon.new

    refute subject.save
    assert_equal ["can't be blank"], subject.errors[:name]
  end

  def test_it_validates_presence_of_pokedex_number
    subject = Pokemon.new

    refute subject.save
    assert_equal ["can't be blank"], subject.errors[:pokedex_number]
  end

  def test_it_saves_pokemon
    assert_equal 0, Pokemon.all.count

    @subject.save

    assert_equal 1, Pokemon.all.count

    saved_pokemon = Pokemon.all.first

    assert_equal "pikachu", saved_pokemon.name
    assert_equal 25, saved_pokemon.pokedex_number
  end

  def test_it_finds_pokemon_by_name
    @subject.save
    pokemon = Pokemon.find_by(name: "Pikachu")

    assert_equal 25, pokemon.pokedex_number
  end

  def test_it_updates_pokemon_with_new_info
    @subject.save
    @subject.update(types: %w[Electric Steel], abilities: ["Static", "Lightning Rod"],
                    stats: { hp: 100, attack: 100, defense: 100, special_attack: 100, special_defense: 100, speed: 100 })

    pokemon = Pokemon.find_by(name: "Pikachu")

    assert_equal 25, pokemon.pokedex_number
    assert_equal %w[Electric Steel], pokemon.types
    assert_equal ["Static", "Lightning Rod"], pokemon.abilities
    assert_equal 100, pokemon.stats[:hp]
    assert_equal 100, pokemon.stats[:attack]
    assert_equal 100, pokemon.stats[:defense]
    assert_equal 100, pokemon.stats[:special_attack]
    assert_equal 100, pokemon.stats[:special_defense]
    assert_equal 100, pokemon.stats[:speed]
  end

  def test_search_by_name
    @subject.save
    @subject.update(name: "mr mime")
    pokemon = Pokemon.search("mime").first

    assert_equal 25, pokemon.pokedex_number
  end

  def test_search_by_type
    @subject.save
    @subject.update(types: ["grass", "poison"])

    pokemon = Pokemon.search("grass").first

    assert_equal 25, pokemon.pokedex_number
  end

  def test_search_by_ability
    @subject.save
    @subject.update(abilities: ["overgrow", "good as gold"])

    pokemon = Pokemon.search("good").first

    assert_equal 25, pokemon.pokedex_number
  end
end
