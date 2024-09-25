# frozen_string_literal: true

module PokemonExternal
  class Client
    include Dry::Monads[:result]

    BASE_URL = "https://www.pokemon.com"

    def initialize(proxy_client: ProxyScrape::Client.new)
      @proxy_client = proxy_client
    end

    def get(resource:, **params)
      PokemonExternal::Resources.const_get(resource.classify).new(self).get(params)
    end

    def connection
      @connection ||= Faraday.new(BASE_URL, proxy: sample_proxy) do |connection|
        connection.headers["User-Agent"] =
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        connection.headers["Referer"] = "https://www.pokemon.com"
        connection.headers["Accept-Language"] = "en-US,en;q=0.9"
        connection.headers["Accept"] =
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8"
        connection.headers["Connection"] = "keep-alive"

        connection.response :json, content_type: "application/json"
        connection.adapter Faraday.default_adapter
      end
    end

    private
      def sample_proxy
        @proxy_client.fetch_proxies
                     .fmap { |proxies| proxies.sample.strip if proxies.any? }
                     .or { nil }
                     .value_or(nil)
      end
  end
end
