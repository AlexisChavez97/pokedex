# frozen_string_literal: true

module PokemonExternal
  class SeleniumClient
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

    def fetch_page(url)
      content = browser do |driver|
        driver.get("#{BASE_URL}#{url}")
        wait = Selenium::WebDriver::Wait.new(timeout: 60)
        wait.until { driver.find_element(tag_name: "body").displayed? }
        simulate_human_behavior(driver)
        driver.page_source
      end

      content
    end

    private
      def with_retries(&block)
        retries = 0
        begin
          yield
        rescue Errno::ECONNREFUSED, Net::ReadTimeout, Selenium::WebDriver::Error::WebDriverError => e
          if retries <= MAX_RETRIES
            sleep(BACKOFF)
            retry
          else
            raise e
          end
        end
      end

      def browser
        driver = Selenium::WebDriver.for(:chrome, options:)

        apply_stealth_mode(driver)

        yield(driver)
      ensure
        driver&.quit
      end

      def options
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument("--headless")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-setuid-sandbox")
        options.add_argument("--disable-blink-features=AutomationControlled")
        options.add_argument("--disable-infobars")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-extensions")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=#{generate_random_viewport[:width]},#{generate_random_viewport[:height]}")
        options.add_argument("--user-agent=#{user_agents.sample}")
        options.add_argument("--proxy-server=#{sample_proxy}") if @use_proxy

        options
      end

      def apply_stealth_mode(driver)
        driver.execute_cdp("Page.addScriptToEvaluateOnNewDocument", source: <<-JS)
          Object.defineProperty(navigator, 'webdriver', {
            get: () => undefined
          });
        JS

        driver.execute_cdp("Network.setUserAgentOverride", userAgent: user_agents.sample, acceptLanguage: "en-US,en;q=0.9")
      end

      def user_agents
        [
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15"
        ]
      end

      def generate_random_viewport
        {
          width: rand(1024..2560),
          height: rand(800..1440)
        }
      end

      def sample_proxy
        ProxyScrape::Client.new.fetch_proxies
                           .fmap { |proxies| proxies.sample.strip if proxies.any? }
                           .or { nil }
                           .value_or(nil)
      end

      def simulate_human_behavior(driver)
        random_viewport_resize(driver)
        natural_mouse_movements(driver)
        realistic_page_scroll(driver)
        realistic_page_scroll(driver)
        random_wait(1, 3)
      end

      def random_viewport_resize(driver)
        new_width = rand(1024..2560)
        new_height = rand(800..1440)
        driver.manage.window.resize_to(new_width, new_height)
      end

      def natural_mouse_movements(driver, movements: 2)
        viewport_width = driver.execute_script("return window.innerWidth;")
        viewport_height = driver.execute_script("return window.innerHeight;")

        movements.times do |i|
          start_x, start_y = rand(0..viewport_width), rand(0..viewport_height)
          end_x, end_y = rand(0..viewport_width), rand(0..viewport_height)

          begin
            driver.action
                  .move_to_location(start_x, start_y)
                  .perform

            driver.action
                  .move_to_location(end_x, end_y, duration: rand(2..5))
                  .perform

          rescue StandardError
          end
          random_wait(0.1, 0.3)
        end
      end

      def realistic_page_scroll(driver)
        total_height = driver.execute_script("return document.body.scrollHeight")
        viewport_height = driver.execute_script("return window.innerHeight")
        scrolls = (total_height.to_f / viewport_height).ceil

        scrolls.times do |i|
          scroll_amount = rand((viewport_height * 0.5)..(viewport_height * 0.9)).to_i
          driver.execute_script("window.scrollBy(0, #{scroll_amount})")
          random_wait(0.5, 1.5)

          # Occasionally scroll back up a bit
          if rand < 0.3
            upscroll_amount = rand((scroll_amount * 0.2)..(scroll_amount * 0.5)).to_i
            driver.execute_script("window.scrollBy(0, -#{upscroll_amount})")
            random_wait(0.5, 1)
          end
        end

        # Scroll back to top with variable speed
        current_scroll = driver.execute_script("return window.pageYOffset")
        while current_scroll > 0
          scroll_amount = [rand(300..700), current_scroll].min
          driver.execute_script("window.scrollBy(0, -#{scroll_amount})")
          current_scroll -= scroll_amount
          random_wait(0.1, 0.3)
        end
      end

      def random_wait(min, max)
        sleep rand(min..max)
      end
  end
end
