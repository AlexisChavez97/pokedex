# frozen_string_literal: true

require "pry"
module PokemonExternal
  class Resource
    include Dry::Monads[:result]

    CACHE_POLICY = -> { Time.now - 86_400 } # 1 day

    attr_reader :client

    def initialize(client)
      @client = client
    end

    private
      def get_request(url, params = {})
        cache_key = "#{url}?#{URI.encode_www_form(params)}"

        ApiRequest.cache(cache_key, CACHE_POLICY) do
          handle_response(client.fetch_page(url))
        end
      end

      def handle_response(response)
        return Failure("Bad response") if bad_response?(response)

        Success(response)
      end

      def blocked?(response)
        response.include?("NOINDEX,NOFOLLOW") || response.include?("ROBOTS")
      end

      def response_empty?(response)
        response.include?("<body></body>")
      end

      def proxy_failed?(response)
        response.include?("took too long to respond")
      end

      def bad_response?(response)
        response_empty?(response) || blocked?(response) || proxy_failed?(response)
      end
  end
end
