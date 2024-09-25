# frozen_string_literal: true

module AppConfig
  class << self
    def load
      @config ||= YAML.load_file(File.join(__dir__, "database.yml"))[ENV["APP_ENV"]]
    end

    def database_url
      load["database_url"]
    end
  end
end

# Initialize the database connection
DB = Sequel.connect(AppConfig.database_url)
DB.extension :pg_json
DB.extension :pg_array
Sequel.extension :pg_array_ops
