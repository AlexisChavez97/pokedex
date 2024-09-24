# frozen_string_literal: true

# Load dependencies
require "bundler/setup"
Bundler.require

# Set default environment to development
ENV["APP_ENV"] ||= "development"
require_relative "environment"

# Setup database schema
require_relative "../db/schema"
Schema.new(DB).setup_schema

# Load base classes first
require_relative "../lib/models/base_model"

# Automatically require all files under the lib/ directory
Dir[File.join(__dir__, "../lib/**/*.rb")].sort.each { |file| require file }
require_relative "../lib/pokedex"