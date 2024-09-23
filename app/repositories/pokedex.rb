# frozen_string_literal: true

class Pokedex
  attr_reader :db
  
  def initialize(db = DB)
    @db = db
    setup_schema
  end

  def setup_schema
    db.create_table? :pokemons do
      primary_key :id
      Integer :pokedex_number
      String :name
      String :types
      String :abilities
      Float :height
      Float :weight
      Integer :hp
      Integer :attack
      Integer :defense
      Integer :special_attack
      Integer :special_defense
      Integer :speed
      DateTime :created_at
      DateTime :updated_at
    end

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