# frozen_string_literal: true

module PokemonExternal
  class Resource
    include Dry::Monads[:result]

    CACHE_POLICY = -> { Time.now - 1 }

    attr_reader :client

    def initialize(client)
      @client = client
    end

    private
      def get_request(url, params = {})
        cache_key = "#{url}?#{URI.encode_www_form(params)}"

        ApiRequest.cache(cache_key, CACHE_POLICY) do
          case client
          when PokemonExternal::SeleniumClient
            handle_selenium(client.fetch_page(url))
          when PokemonExternal::Client
            handle_http(client.connection.get(url, params))
          end
        end
      end

      def handle_http(response)
        return Failure("Not Found") if response.status == 404
        return Failure("Bad Request") if response.status == 400
        return Failure("Empty response") if response.body.empty?

        Success(response.body)
      end

      def handle_selenium(response)
        return Failure("Bad response") if bad_response?(response)

        Success(response)
      end

      def blocked?(response)
        response.include?("noindex,nofollow")
      end

      def response_empty?(response)
        response.include?("Imperva") || response.include?("<body></body>")
      end

      def bad_response?(response)
        response_empty?(response) || blocked?(response)
      end
  end
end
