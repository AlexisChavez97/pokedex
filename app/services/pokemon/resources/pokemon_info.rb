# frozen_string_literal: true

module Pokemon
  module Resources
    class PokemonInfo < Resource
      def get(params)
        pokemon_name = params[:name].downcase
        get_request("/us/pokedex/#{pokemon_name}").fmap { |response| response }
      end
    end
  end
end