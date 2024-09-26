# frozen_string_literal: true

class Pokemon < BaseModel
  table :pokemons

  attr_accessor :id, :pokedex_number, :name, :types, :abilities, :updated_at, :created_at, :stats

  validate_presence_of :name, :pokedex_number

  columns :pokedex_number, :name, :types, :stats, :abilities, :updated_at, :created_at

  CACHE_POLICY = 300 # 5 minutes in seconds
  @@search_cache = {}

  def initialize(attributes = {})
    super
    @types ||= []
    @abilities ||= []
    @stats ||= {}
  end

  def self.search(query)
    cache_key = query.downcase
    cached_result = @@search_cache[cache_key]

    if cached_result && (Time.now - cached_result[:timestamp] < CACHE_POLICY)
      return cached_result[:results]
    end

    results = perform_search(query)
    @@search_cache[cache_key] = { results:, timestamp: Time.now }
    results
  end

  def self.perform_search(query)
    conditions = []
    conditions << Sequel.ilike(:name, "%#{query}%")
    conditions << { pokedex_number: query.to_i } if query.to_i > 0

    conditions << Sequel.lit("EXISTS (SELECT 1 FROM unnest(types) AS t WHERE t ILIKE ?)", "%#{query}%")
    conditions << Sequel.lit("EXISTS (SELECT 1 FROM unnest(abilities) AS a WHERE a ILIKE ?)", "%#{query}%")

    return [] if conditions.empty?

    dataset.where(Sequel.|(*conditions))
           .order(:pokedex_number)
           .all
           .map { |attributes| new(parse_attributes(attributes)) }
  end

  def info
    {
      abilities:,
      types:,
      stats:
    }
  end

  def info_is_empty?
    info.all? { |_, value| value.empty? }
  end

  def humanized_name
    name.split("-").map(&:capitalize).join(" ")
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
      super.merge(
        types: types.empty? ? Sequel.pg_array([], :text) : Sequel.pg_array(types),
        abilities: abilities.empty? ? Sequel.pg_array([], :text) : Sequel.pg_array(abilities),
        stats: Sequel.pg_jsonb(stats)
      )
    end
end
