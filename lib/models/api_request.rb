# frozen_string_literal: true

class ApiRequest < BaseModel
  table :api_requests

  attr_accessor :id, :url, :response_data, :created_at, :updated_at

  validate_presence_of :url

  columns :url, :response_data, :created_at, :updated_at

  def self.find_by_url(url)
    find_by(url: url)
  end

  def self.cache(url, cache_policy)
    instance = find_by_url(url) || new(url: url)
    instance.cache(cache_policy) { yield if block_given? }
  end

  def cache(cache_policy)
    return Success(response_data) if cached?(cache_policy)

    result = yield
    update_cache(result) if result.success?
    result
  end

  private
    def cached?(cache_policy)
      !new_record? && updated_at && updated_at >= cache_policy.call
    end

    def update_cache(result)
      self.response_data = result.value!.to_json
      save
    end

    def body
      JSON.parse(response_data)["body"] if response_data
    rescue JSON::ParserError
      nil
    end

    def new_record?
      id.nil?
    end
end
