# frozen_string_literal: true

ENV["APP_ENV"] = "test"

require_relative "../config/application"
require_relative "../db/schema"
require "minitest/autorun"
require "timecop"

TEST_DB_URL = "postgres://postgres:postgres@localhost/test_pokedex_db"

class Minitest::Test
  include Dry::Monads[:result]

  def setup
    DB.tables.each { |table| DB[table].delete }
    Schema.new(DB).setup_schema
  end

  def mock_pokemon_index_response
    File.read(File.join(File.dirname(__FILE__), "fixtures", "pokemon_index.html"))
  end

  def mock_pokemon_info_response
    File.read(File.join(File.dirname(__FILE__), "fixtures", "pokemon_info.html"))
  end
end
