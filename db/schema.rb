# frozen_string_literal: true

class Schema
  attr_reader :db

  def initialize(db = DB)
    @db = db
    setup_schema
  end

  def setup_schema
    setup_pokemons_table
    setup_api_requests_table
  end

  private

  def setup_pokemons_table
    db.create_table? :pokemons do
      primary_key :id
      Integer :pokedex_number, unique: true, index: true, null: false
      String :name, unique: true, index: true, null: false
      column :types, 'text[]'
      column :abilities, 'text[]'
      Json :stats
      DateTime :created_at
      DateTime :updated_at
    end

    unless db.indexes(:pokemons).key?(:idx_pokemons_types)
      db.run('CREATE INDEX idx_pokemons_types ON pokemons USING gin (types)')
    end

    return if db.indexes(:pokemons).key?(:idx_pokemons_abilities)

    db.run('CREATE INDEX idx_pokemons_abilities ON pokemons USING gin (abilities)')
  end

  def setup_api_requests_table
    db.create_table? :api_requests do
      primary_key :id
      String :url, null: false
      Json :response_data
      DateTime :created_at
      DateTime :updated_at

      index :url, unique: true
    end
  end
end
