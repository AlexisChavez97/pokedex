# frozen_string_literal: true

module Pokemon
  class SeleniumClient
    BASE_URL = "https://www.pokemon.com"

    def get(resource:, **params)
      Pokemon::Resources.const_get(resource.classify).new(self).get(params)
    end

    def driver
      @driver ||= Selenium::WebDriver.for :chrome, options: headless_options
    end

    def fetch_page(url)
      driver.navigate.to("#{BASE_URL}#{url}")
      driver.page_source
    ensure
      driver.quit
    end

    private

    def headless_options
      options = Selenium::WebDriver::Chrome::Options.new
      options.add_argument("--headless")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1280,800")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--user-agent=#{user_agents.sample}")
      options.add_argument("--proxy-server=#{sample_proxy}")
      options
    end

    def user_agents
      [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"
      ]
    end

    def sample_proxy
      ProxyScrape::Client.new.fetch_proxies
        .fmap { |proxies| proxies.sample.strip if proxies.any? }
        .or do |error|
          puts "Failed to fetch proxies: #{error}, defaulting to no proxy"
          nil
        end.value_or(nil)
    end
  end
end