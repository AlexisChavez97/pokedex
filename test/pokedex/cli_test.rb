# frozen_string_literal: true

require_relative "../test_helper"
require "ostruct"

class Pokedex::CLITest < Minitest::Test
  def setup
    @scraper = Minitest::Mock.new
    @scraper.expect(:stop_fetching, nil)
    @cli = Pokedex::CLI.new(scraper: @scraper)
  end

  def test_start_with_exit
    input = StringIO.new("exit\n")
    output = StringIO.new

    @scraper.expect(:fetch_and_save_pokemon_index, Success(:populated), use_proxy: false)
    @scraper.expect(:queue_and_fetch_all_pokemon_info, nil)

    simulate_cli_run(input, output) do
      @cli.start
    end

    assert_match(/Goodbye!/, output.string)
    @scraper.verify
  end

  def test_search_with_no_results
    input = StringIO.new("nonexistent\nexit\n")
    output = StringIO.new

    @scraper.expect(:fetch_and_save_pokemon_index, Success(:populated), use_proxy: false)
    @scraper.expect(:queue_and_fetch_all_pokemon_info, nil)

    Pokemon.stub :search, [] do
      simulate_cli_run(input, output) do
        @cli.start
      end
    end

    assert_match(/No results found for 'nonexistent'/, output.string)
    @scraper.verify
  end

  def test_search_with_results_and_display_populated_info
    input = StringIO.new("pikachu\n1\nexit\n")
    output = StringIO.new

    @scraper.expect(:fetch_and_save_pokemon_index, Success(:populated), use_proxy: false)
    @scraper.expect(:queue_and_fetch_all_pokemon_info, nil)

    mock_pokemon = OpenStruct.new(
      name: "Pikachu",
      pokedex_number: 25,
      types: ["Electric"],
      abilities: ["Static"],
      stats: { hp: 15, attack: 15, defense: 10, special_attack: 10, special_defense: 10, speed: 10 },
      info_is_empty?: false,
      humanized_name: "Pikachu"
    )

    Pokemon.stub :search, [mock_pokemon] do
      simulate_cli_run(input, output) do
        @cli.start
      end
    end

    expected_output = <<~OUTPUT
      Initializing Pokedex...
      Fetching and saving Pokemon...
      Missing Pokémon data will continue to be fetched in the background.

      Enter a Pokémon name to search (or type 'exit' to quit):
      Found 1 result(s):
      1. Pikachu (25)
      Enter the number of the Pokémon you want to see details for:

      Pokémon: Pikachu (25)
      Types: Electric
      Abilities: Static

      Hp              [████████████████████] 15/15

      Attack          [████████████████████] 15/15

      Defense         [█████████████░░░░░░░] 10/15

      Special Attack  [█████████████░░░░░░░] 10/15

      Special Defense [█████████████░░░░░░░] 10/15

      Speed           [█████████████░░░░░░░] 10/15

      Enter a Pokémon name to search (or type 'exit' to quit):
      Goodbye!
    OUTPUT

    assert_equal expected_output.strip, output.string.strip

    @scraper.verify
  end

  def test_search_with_results_and_display_missing_info_notice
    input = StringIO.new("pikachu\n1\nexit\n")
    output = StringIO.new

    @scraper.expect(:fetch_and_save_pokemon_index, Success(:populated), use_proxy: false)
    @scraper.expect(:queue_and_fetch_all_pokemon_info, nil)
    @scraper.expect(:priority_enqueue, nil, [Object])

    mock_pokemon = OpenStruct.new(
      name: "Pikachu",
      pokedex_number: 25,
      types: [],
      abilities: [],
      stats: {},
      info_is_empty?: true,
      humanized_name: "Pikachu"
    )

    Pokemon.stub :search, [mock_pokemon] do
      simulate_cli_run(input, output) do
        @cli.start
      end
    end

    expected_output = <<~OUTPUT
      Initializing Pokedex...
      Fetching and saving Pokemon...
      Missing Pokémon data will continue to be fetched in the background.

      Enter a Pokémon name to search (or type 'exit' to quit):
      Found 1 result(s):
      1. Pikachu (25)
      Enter the number of the Pokémon you want to see details for:

      Pokémon: Pikachu (25)
      Types:#{' '}
      Abilities:#{' '}

      Note: Detailed information for Pikachu is currently being fetched.
      Please check again in a few moments for complete information.

      Enter a Pokémon name to search (or type 'exit' to quit):
      Goodbye!
    OUTPUT

    assert_equal expected_output.strip, output.string.strip

    @scraper.verify
  end

  def test_search_with_multiple_results_and_display_missing_info_notice
    input = StringIO.new("electric\n1\nexit\n")
    output = StringIO.new

    @scraper.expect(:fetch_and_save_pokemon_index, Success(:populated), use_proxy: false)
    @scraper.expect(:queue_and_fetch_all_pokemon_info, nil)
    @scraper.expect(:priority_enqueue, nil, [Object])

    mock_pikachu = OpenStruct.new(
      name: "Pikachu",
      pokedex_number: 25,
      types: [],
      abilities: [],
      stats: {},
      info_is_empty?: true,
      humanized_name: "Pikachu"
    )

    mock_raichu = OpenStruct.new(
      name: "Raichu",
      pokedex_number: 26,
      types: [],
      abilities: [],
      stats: {},
      info_is_empty?: true,
      humanized_name: "Raichu"
    )

    Pokemon.stub :search, [mock_pikachu, mock_raichu] do
      simulate_cli_run(input, output) do
        @cli.start
      end
    end

    expected_output = <<~OUTPUT
      Initializing Pokedex...
      Fetching and saving Pokemon...
      Missing Pokémon data will continue to be fetched in the background.

      Enter a Pokémon name to search (or type 'exit' to quit):
      Found 2 result(s):
      1. Pikachu (25)
      2. Raichu (26)
      Enter the number of the Pokémon you want to see details for:

      Pokémon: Pikachu (25)
      Types:#{' '}
      Abilities:#{' '}

      Note: Detailed information for Pikachu is currently being fetched.
      Please check again in a few moments for complete information.

      Enter a Pokémon name to search (or type 'exit' to quit):
      Goodbye!
    OUTPUT

    assert_equal expected_output.strip, output.string.strip

    @scraper.verify
  end

  private
    def simulate_cli_run(input, output)
      $stdin = input
      $stdout = output
      yield
    ensure
      $stdin = STDIN
      $stdout = STDOUT
    end
end
