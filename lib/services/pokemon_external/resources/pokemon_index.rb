# frozen_string_literal: true

module PokemonExternal
  module Resources
    class PokemonIndex < Resource
      def get(_params = {})
        get_request("/us/pokedex").fmap { |response| response }
      end
    end
  end
end
