# frozen_string_literal: true

module Pokemon
  module Resources
    class PokemonDetails < Resource
      def get(params)
        pokemon_name = params[:name].downcase
        get_request("/el/pokedex/#{pokemon_name}").fmap { |response| response }
      end
    end
  end
end