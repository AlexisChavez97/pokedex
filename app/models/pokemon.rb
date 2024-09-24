# frozen_string_literal: true
require "pry-byebug"
module Models
  class Pokemon
    attr_accessor :id, :pokedex_number, :name, :types, :abilities, :updated_at, :created_at, :stats

    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
      end
      @types ||= []
      @abilities ||= []
      @stats ||= {}
    end

    def self.all
      DB[:pokemons].all.map { |attributes| new(parse_attributes(attributes)) }
    end

    def self.find_by_name(name)
      DB[:pokemons].where(Sequel.ilike(:name, "%#{name}%")).all.map { |attributes| new(parse_attributes(attributes)) }
    end
    
    def self.delete_all
      DB[:pokemons].delete
    end

    def self.create(attributes)
      new(attributes).save
    end

    def update(attributes)
      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
      save
    end

    def save
      now = Time.now
      self.updated_at = now
      self.created_at ||= now

      attributes = to_h

      if id
        DB[:pokemons].where(id: id).update(attributes)
      else
        self.id = DB[:pokemons].insert(attributes)
      end
      self
    end

    def bulk_insert(pokemon_list)
      DB.transaction do
        DB[:pokemons].multi_insert(pokemon_list.map { |pokemon| pokemon.to_h.merge(stats: JSON.generate(pokemon.stats)) })
      end
    end

    def info
      {
        abilities: abilities,
        types: types,
        stats: stats
      }
    end

    def info_is_empty?
      info.all? { |key, value| value.empty? }
    end

    private
      def self.parse_attributes(attributes)
        attributes.merge(
          types: attributes[:types] || [],
          abilities: attributes[:abilities] || [],
          stats: ActiveSupport::HashWithIndifferentAccess.new(
            attributes[:stats].is_a?(String) ? JSON.parse(attributes[:stats]) : attributes[:stats]
          ).deep_symbolize_keys
        )
      end
    
      def to_h
        {
          pokedex_number: pokedex_number,
          name: name,
          types: types.empty? ? Sequel.pg_array([], :text) : Sequel.pg_array(types),
          abilities: abilities.empty? ? Sequel.pg_array([], :text) : Sequel.pg_array(abilities),
          stats: Sequel.pg_jsonb(stats),
          created_at: created_at,
          updated_at: updated_at
        }
      end
  end
end