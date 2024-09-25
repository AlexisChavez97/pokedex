# frozen_string_literal: true

module Pokedex
  class << self
    def start
      CLI.new.start
    end
  end
end
