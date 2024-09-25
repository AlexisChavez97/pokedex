# frozen_string_literal: true

require_relative "../test_helper"

class Pokedex::ParserTest < Minitest::Test
  def setup
    @parser = Pokedex::Parser.new
    @index_html = File.read("test/fixtures/pokemon_index.html")
    @index_html_with_special_characters = File.read("test/fixtures/pokemon_with_special_characters_index.html")
    @info_html = File.read("test/fixtures/pokemon_info.html")
  end

  def test_parse_pokemon_index
    result = @parser.parse_pokemon_index(@index_html)
    assert_equal(
      [{ pokedex_number: 1, name: "bulbasaur" }, { pokedex_number: 2, name: "ivysaur" },
      { pokedex_number: 3, name: "venusaur" }],
      result.value!
    )
  end

  def test_parse_pokemon_index_with_special_characters
    result = @parser.parse_pokemon_index(@index_html_with_special_characters)
    assert_equal(
      [{ pokedex_number: 1001, name: "wo-chien" }, { pokedex_number: 1003, name: "sirfetchd" },
      { pokedex_number: 1004, name: "mr-rime" }, { pokedex_number: 32, name: "nidoran-male" }],
      result.value!
    )
  end

  def test_parse_pokemon_info
    result = @parser.parse_pokemon_info(@info_html)

    assert_equal(
      { types: ["Grass", "Poison"], abilities: ["Overgrow"],
      stats: { hp: 3, attack: 0, defense: 3, special_attack: 0, special_defense: 3, speed: 0 } },
      result.value!
    )
  end
end
