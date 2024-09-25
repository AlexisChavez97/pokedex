# frozen_string_literal: true

module ProxyScrape
  class Client
    include Dry::Monads[:result]

    BASE_URL = "https://api.proxyscrape.com"

    def fetch_proxies
      Success(premium_proxies_list)

      # response = connection.get("/v4/free-proxy-list/get", {
      #   request: "display_proxies",
      #   proxy_format: "protocolipport",
      #   format: "text",
      #   anonymity: "elite",
      #   protocol: "http",
      #   country: "us",
      #   timeout: 500
      # })

      # handle_response(response)
    end

    private
      def connection
        @connection ||= Faraday.new(BASE_URL) do |conn|
          conn.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
          conn.headers["Accept"] = "text/plain"
          conn.adapter Faraday.default_adapter
        end
      end

      def handle_response(response)
        if response.success?
          Success(response.body.split("\n"))
        else
          Failure("Failed to fetch proxies: #{response.status}")
        end
      end

      def premium_proxies_list
        proxies = File.read(File.join(__dir__, "premium_proxies.txt")).split("\n")
        proxies.map! { |proxy| "http://#{proxy.strip}" }
      end
  end
end
