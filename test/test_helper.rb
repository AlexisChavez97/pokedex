# frozen_string_literal: true

ENV["APP_ENV"] = "test"

require_relative "../config/application"
require "minitest/autorun"
require "webmock/minitest"
require "timecop"

TEST_DB_URL = "postgres://postgres:postgres@localhost/test_pokedex_db"

class Minitest::Test
  def setup
    DB.tables.each { |table| DB[table].delete }
    Pokedex.new(DB).setup_schema
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  def teardown
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  def mock_pokemon_index_response
    File.read(File.join(File.dirname(__FILE__), "fixtures", "pokemon_index.html"))
  end

  def mock_pokemon_details_response
    File.read(File.join(File.dirname(__FILE__), "fixtures", "pokemon_details.html"))
  end
end