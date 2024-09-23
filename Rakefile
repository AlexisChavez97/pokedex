# frozen_string_literal: true

require_relative "config/application"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.pattern = "test/**/*_test.rb"
  t.verbose = true
end

task default: :test