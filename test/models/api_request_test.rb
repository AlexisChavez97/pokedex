# frozen_string_literal: true

require_relative "../test_helper"

class ApiRequestTest < Minitest::Test
  def setup
    super
    @base_url = "https://www.pokemon.com"
    @pokemon_index_path = "/us/pokedex"
    @pokemon_info_path = "/us/pokedex/bulbasaur"
    @cache_policy = -> { Time.now - 300 } # 5 minutes ago
  end

  def test_validate_presence_of_url
    subject = ApiRequest.new

    refute subject.save

    assert_equal ["can't be blank"], subject.errors[:url]
    assert_equal 0, ApiRequest.all.count
  end

  def test_it_should_not_save_api_request_without_url
    subject = ApiRequest.new

    refute subject.save
    assert_equal 0, ApiRequest.all.count
  end

  def test_it_should_save_subject_with_url
    subject = ApiRequest.new(url: "#{@base_url}#{@pokemon_index_path}")

    assert subject.save
    assert_equal 1, ApiRequest.all.count
  end

  def test_it_should_not_save_subject_with_same_url
    subject_1 = ApiRequest.new(url: "#{@base_url}#{@pokemon_index_path}")
    subject_2 = ApiRequest.new(url: "#{@base_url}#{@pokemon_index_path}")

    assert subject_1.save
    refute subject_2.save
    assert_equal 1, ApiRequest.all.count
  end

  def test_it_should_save_subject_with_different_url
    subject_1 = ApiRequest.new(url: "#{@base_url}#{@pokemon_index_path}")
    subject_2 = ApiRequest.new(url: "#{@base_url}#{@pokemon_info_path}")

    assert subject_1.save
    assert subject_2.save
    assert_equal 2, ApiRequest.all.count
  end

  def test_cache_new_request
    result = Success(mock_pokemon_index_response)
    api_request = ApiRequest.cache("#{@base_url}#{@pokemon_index_path}", @cache_policy) { result }
    
    assert_kind_of Dry::Monads::Success, api_request
    
    stored_request = ApiRequest.find_by_url("#{@base_url}#{@pokemon_index_path}")

    assert_equal mock_pokemon_index_response, stored_request.response_data
  end

  def test_cache_existing_request
    initial_result = Success(mock_pokemon_index_response)
    ApiRequest.cache("#{@base_url}#{@pokemon_index_path}", @cache_policy) { initial_result }
    
    updated_result = Success("updated data")
    api_request = ApiRequest.cache("#{@base_url}#{@pokemon_index_path}", @cache_policy) { updated_result }
    
    assert_kind_of Dry::Monads::Success, api_request
    
    stored_request = ApiRequest.find_by_url("#{@base_url}#{@pokemon_index_path}")

    assert_equal mock_pokemon_index_response, stored_request.response_data
  end

  def test_cache_expired_request
    initial_result = Success(mock_pokemon_index_response)
    ApiRequest.cache("#{@base_url}#{@pokemon_index_path}", @cache_policy) { initial_result }
    
    Timecop.travel(Time.now + 600) # Travel 10 minutes into the future
    
    updated_result = Success(mock_pokemon_info_response)
    api_request = ApiRequest.cache("#{@base_url}#{@pokemon_index_path}", @cache_policy) { updated_result }
    
    assert_kind_of Dry::Monads::Success, api_request
    
    stored_request = ApiRequest.find_by_url("#{@base_url}#{@pokemon_index_path}")
    assert_equal mock_pokemon_info_response, stored_request.response_data
  end

  def test_cache_failure_result
    result = Failure("API error")
    
    api_request = ApiRequest.cache("#{@base_url}#{@pokemon_index_path}", @cache_policy) { result }
    
    assert_kind_of Dry::Monads::Failure, api_request
    assert_equal "API error", api_request.failure
    
    stored_request = ApiRequest.find_by_url("#{@base_url}#{@pokemon_index_path}")
    assert_nil stored_request
  end
end