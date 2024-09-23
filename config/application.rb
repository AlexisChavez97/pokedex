# frozen_string_literal: true

require "active_support/inflector"
require "bundler/setup"
Bundler.require

# Set default environment to development
ENV["APP_ENV"] ||= "development"

require_relative "environment"

# Automatically require all files under the app/ directory
Dir[File.join(__dir__, "../app/**/*.rb")].sort.each { |file| require file }