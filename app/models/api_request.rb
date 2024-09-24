# frozen_string_literal: true

module Models
  class ApiRequest
    include Dry::Monads[:result]
    
    attr_accessor :id, :url, :response_data, :created_at, :updated_at

    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?("#{key}=")
      end
    end

    def self.all
      DB[:api_requests].all.map { |attributes| new(attributes) }
    end

    def self.find_by_url(url)
      DB[:api_requests].where(url: url).first&.then { |attributes| new(attributes) }
    end

    def self.cache(url, cache_policy)
      instance = find_by_url(url) || new(url: url)
      instance.cache(cache_policy) { yield if block_given? }
    end

    def save
      return false if url.nil? || url.empty?

      now = Time.now
      self.updated_at = now
      self.created_at ||= now
  
      attributes = to_h
  
      if id
        DB[:api_requests].where(id: id).update(attributes)
      else
        existing_record = self.class.find_by_url(url)
        return false if existing_record

        self.id = DB[:api_requests].insert(attributes)
      end
      true
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

    private
      def new_record?
        id.nil?
      end

      def to_h
        {
          url: url,
          response_data: response_data,
          created_at: created_at,
          updated_at: updated_at
        }
      end
  end
end