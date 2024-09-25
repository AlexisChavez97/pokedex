# frozen_string_literal: true

module Pokedex
  class Parser
    include Dry::Monads[:result]

    def parse_pokemon_index(html)
      doc = Nokogiri::HTML(html)
      pokemon_list = []

      doc.css("noscript ul li").each do |pokemon_li|
        link = pokemon_li.at_css("a")
        name = link["href"].split("/").last
        number = link.text.split("-").first.strip.delete(",")

        pokemon_list << { pokedex_number: number.to_i, name: }
      end

      Success(pokemon_list)
    rescue StandardError => e
      Failure("Error parsing Pokémon index: #{e.message}")
    end

    def parse_pokemon_info(html)
      doc = Nokogiri::HTML(html)
      types = extract_types(doc)
      abilities = extract_abilities(doc)
      stats = extract_stats(doc)

      pokemon_info = {
        types:,
        abilities:,
        stats:
      }

      Success(pokemon_info)
    rescue StandardError => e
      Failure("Error parsing Pokémon info: #{e.message}")
    end

    private
      def extract_types(doc)
        doc.css(".dtm-type ul li a").map(&:text)
      end

      def extract_abilities(doc)
        doc.css(".attribute-list li a .attribute-value").map(&:text)
      end

      def extract_stats(doc)
        stats_map = {}
        stats_elements = doc.css(".pokemon-stats-info ul > li")

        stats_elements.each do |stat_element|
          next if stat_element.css("span").text.empty?

          stat_name = stat_element.css("span").text.downcase.tr(" ", "_").to_sym
          stat_value = stat_element.css(".gauge .meter").attr("data-value").to_s.to_i
          stats_map[stat_name] = stat_value
        end

        stats_map
      end
  end
end
