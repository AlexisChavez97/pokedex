# frozen_string_literal: true

module Models
  class Pokemon
    attr_accessor :id, :pokedex_number, :name, :types, :abilities,
                  :height, :weight, :hp, :attack, :defense, :special_attack,
                  :special_defense, :speed, :updated_at, :created_at

    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
      end
    end

    def self.all
      DB[:pokemons].all.map { |attributes| new(attributes) }
    end

    def self.find_by_name(name)
      DB[:pokemons].where(Sequel.ilike(:name, "%#{name}%")).all.map { |attributes| new(attributes) }
    end

    def save
      now = Time.now
      self.updated_at = now
      self.created_at ||= now

      if id
        DB[:pokemons].where(id: id).update(to_h)
      else
        self.id = DB[:pokemons].insert(to_h)
      end
      self
    end

    def bulk_insert(pokemon_list)
      DB.transaction do
        DB[:pokemons].multi_insert(pokemon_list.map(&:to_h))
      end
    end

    private
      def to_h
        instance_variables.each_with_object({}) do |var, hash|
          key = var.to_s.delete("@").to_sym
          hash[key] = instance_variable_get(var)
        end
      end
  end
end