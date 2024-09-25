# frozen_string_literal: true

require "playwright"

module PokemonExternal
  class PlaywrightClient
    BASE_URL = "https://www.pokemon.com"
    MAX_RETRIES = Float::INFINITY
    BACKOFF = 5

    def initialize
      playwright
    end

    def get(resource:, use_proxy:, **params)
      with_retries do
        PokemonExternal::Resources.const_get(resource.classify).new(self).get(params)
      end
    end

    def fetch_page(url)
      content = browser do |context|
        page = context.new_page
        page.set_viewport_size(generate_random_viewport)

        page.goto("#{BASE_URL}/#{url}")
        page.wait_for_load_state(state: "networkidle")

        simulate_human_behavior(page)

        page.content
      end

      content
    rescue Playwright::Error => e
      raise "Failed to fetch page: #{e.message}"
    end

    private
      def with_retries(&block)
        retries = 0
        begin
          yield
        rescue Playwright::Error => e
          if retries <= MAX_RETRIES
            sleep(BACKOFF)
            retry
          else
            raise e
          end
        end
      end

      def playwright
        @playwright ||= Playwright.create(playwright_cli_executable_path: "npx playwright").playwright
      end

      def browser(&block)
        context = chromium.new_context
        block.call(context)
      ensure
        context&.close
      end

      def chromium
        @chromium ||= @playwright.chromium.launch(headless: true, args:)
      end

      def args
        [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-blink-features=AutomationControlled",
          "--disable-infobars",
          "--disable-dev-shm-usage",
          "--disable-extensions",
          "--disable-gpu",
          "--disable-software-rasterizer",
          "--disable-web-security",
          "--disable-features=IsolateOrigins,site-per-process",
          "--disable-blink-features=AutomationControlled",
        ]
      end

      def generate_random_viewport
        {
          width: rand(1024..2560),
          height: rand(800..1440)
        }
      end

      def simulate_human_behavior(page)
        random_viewport_resize(page)
        natural_mouse_movements(page)
        realistic_page_scroll(page)
        random_wait(1, 3)
      end

      def random_viewport_resize(page)
        new_width = rand(1024..2560)
        new_height = rand(800..1440)
        page.set_viewport_size(width: new_width, height: new_height)
      end

      def natural_mouse_movements(page, movements: 2)
        viewport_width = page.evaluate("window.innerWidth")
        viewport_height = page.evaluate("window.innerHeight")

        movements.times do
          start_x, start_y = rand(0..viewport_width), rand(0..viewport_height)
          end_x, end_y = rand(0..viewport_width), rand(0..viewport_height)

          page.mouse.move(start_x, start_y)
          page.mouse.move(end_x, end_y, steps: rand(2..5))

          random_wait(0.1, 0.3)
        end
      end

      def realistic_page_scroll(page)
        total_height = page.evaluate("document.body.scrollHeight")
        viewport_height = page.evaluate("window.innerHeight")
        scrolls = (total_height.to_f / viewport_height).ceil

        scrolls.times do
          scroll_amount = rand((viewport_height * 0.5)..(viewport_height * 0.9)).to_i
          page.evaluate("window.scrollBy(0, #{scroll_amount})")
          random_wait(0.5, 1.5)

          # Occasionally scroll back up a bit
          if rand < 0.3
            upscroll_amount = rand((scroll_amount * 0.2)..(scroll_amount * 0.5)).to_i
            page.evaluate("window.scrollBy(0, -#{upscroll_amount})")
            random_wait(0.5, 1)
          end
        end

        # Scroll back to top with variable speed
        current_scroll = page.evaluate("window.pageYOffset")
        while current_scroll > 0
          scroll_amount = [rand(300..700), current_scroll].min
          page.evaluate("window.scrollBy(0, -#{scroll_amount})")
          current_scroll -= scroll_amount
          random_wait(0.1, 0.3)
        end
      end

      def random_wait(min, max)
        sleep rand(min..max)
      end
  end
end
