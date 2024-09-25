# frozen_string_literal: true

module PokemonExternal
  class WebCrawler
    BASE_URL = "https://www.pokemon.com"
    MAX_RETRIES = Float::INFINITY
    BACKOFF = 10

    def initialize
      @use_proxy = false
    end

    def get(resource:, use_proxy:, **params)
      @use_proxy = use_proxy

      with_retries do
        PokemonExternal::Resources.const_get(resource.classify).new(self).get(params)
      end
    end

    def driver
      @driver ||= Selenium::WebDriver.for :chrome, options: headless_options
    end

    def fetch_page(url)
      puts "Attempting to fetch Pokédex data..."

      driver.navigate.to("#{BASE_URL}#{url}")
      wait = Selenium::WebDriver::Wait.new(timeout: 20)
      wait.until { driver.find_element(tag_name: "body").displayed? }
      simulate_human_behavior
      driver.page_source
    ensure
      driver.quit
    end

    private
      def with_retries(&block)
        retries = 0
        begin
          Timeout.timeout(30, &block)
        rescue Errno::ECONNREFUSED, Net::ReadTimeout, Selenium::WebDriver::Error::WebDriverError => e
          if retries <= MAX_RETRIES
            sleep(BACKOFF)
            reset_driver
            retry
          else
            raise e
          end
        rescue StandardError => e
          reset_driver
          retry
        end
      end

      def headless_options
        options = Selenium::WebDriver::Chrome::Options.new
        # options.add_argument("--headless")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1280,800")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--user-agent=#{user_agents.sample}")
        if @use_proxy
          proxy = sample_proxy
          puts "Spinning up proxy..."
          options.add_argument("--proxy-server=#{proxy}")
        end
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
                           .or { nil }
                           .value_or(nil)
      end

      def simulate_human_behavior
        scroll_randomly
        random_wait(1, 10)
        move_mouse_randomly
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
      rescue Selenium::WebDriver::Error::MoveTargetOutOfBoundsError
      end

      def random_wait(min, max)
        sleep rand(min..max)
      end

      def reset_driver
        @driver = nil
      end
  end
end
