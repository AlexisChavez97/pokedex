# frozen_string_literal: true

module PokemonExternal
  class SeleniumClient
    BASE_URL = "https://www.pokemon.com"

    def get(resource:, **params)
      PokemonExternal::Resources.const_get(resource.classify).new(self).get(params)
    end

    def driver
      @driver ||= Selenium::WebDriver.for :chrome, options: headless_options
    end

    def fetch_page(url)
      driver.navigate.to("#{BASE_URL}#{url}")
      puts "Fetching details for: #{url}"
      wait = Selenium::WebDriver::Wait.new(timeout: 10)
      wait.until { driver.find_element(tag_name: "body").displayed? }
      simulate_human_behavior
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
        # proxy = sample_proxy
        # puts "Using proxy: #{proxy}"
        # options.add_argument("--proxy-server=#{proxy}")
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

      def simulate_human_behavior
        scroll_randomly
        random_wait(1, 10)
        move_mouse_randomly
      rescue => e
        puts "Error during human behavior simulation: #{e.message}. Continuing..."
      end

      def scroll_randomly
        scroll_height = driver.execute_script("return Math.max(document.body.scrollHeight, document.documentElement.scrollHeight, document.body.offsetHeight, document.documentElement.offsetHeight, document.body.clientHeight, document.documentElement.clientHeight);")
        (1..rand(3..5)).each do |_|
          driver.execute_script("window.scrollTo(0, #{rand(scroll_height)});")
          random_wait(1, 10)
        end
      end

      def move_mouse_randomly
        viewport_width = driver.execute_script("return window.innerWidth;")
        viewport_height = driver.execute_script("return window.innerHeight;")
        x = rand(viewport_width)
        y = rand(viewport_height)
        driver.action.move_by(x, y).perform
      rescue Selenium::WebDriver::Error::MoveTargetOutOfBoundsError => e
        puts "Mouse movement error: #{e.message}. Skipping this action."
      end

      def random_wait(min, max)
        sleep rand(min..max)
      end
  end
end
