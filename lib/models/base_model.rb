# frozen_string_literal: true

class BaseModel
  include Dry::Monads[:result]

  class << self
    attr_reader :table_name, :presence_validations

    def table(name)
      @table_name = name
    end

    def dataset
      DB[table_name]
    end

    def validate_presence_of(*attributes)
      @presence_validations ||= []
      @presence_validations.concat(attributes)
    end

    def all
      dataset.all.map { |attributes| new(parse_attributes(attributes)) }
    end

    def find_by(conditions)
      normalized_conditions = conditions.transform_values { |value| value.to_s.downcase }

      dataset.where(normalized_conditions).first&.then { |attributes| new(parse_attributes(attributes)) }
    end

    def create(attributes)
      new(attributes).save
    end

    def bulk_insert(records)
      dataset.multi_insert(records)
    end

    def delete_all
      dataset.delete
    end

    def parse_attributes(attributes)
      attributes
    end

    def columns(*cols)
      @columns = cols
    end

    def columns_list
      @columns ||= dataset.columns
    end
  end

  def initialize(attributes = {})
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
  end

  def save
    return false unless valid?

    set_timestamps
    attributes = to_h

    begin
      persist_record(attributes)
      true
    rescue Sequel::UniqueConstraintViolation, Sequel::NotNullConstraintViolation => e
      handle_constraint_violation(e)
      false
    end
  end

  def update(attributes)
    attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
    end
    save
  end

  def validate
    self.class.presence_validations&.each do |attribute|
      value = send(attribute)
      errors.add(attribute, "can't be blank") if value.nil? || value.to_s.strip.empty?
    end
  end

  def valid?
    errors.clear
    validate
    errors.empty?
  end

  def errors
    @errors ||= ErrorCollection.new
  end

  private
    def set_timestamps
      now = Time.now
      self.updated_at = now
      self.created_at ||= now
    end

    def persist_record(attributes)
      if id
        update_existing_record(attributes)
      else
        create_new_record(attributes)
      end
    end

    def update_existing_record(attributes)
      self.class.dataset.where(id:).update(attributes)
    end

    def create_new_record(attributes)
      self.id = self.class.dataset.insert(attributes)
    end

    def handle_constraint_violation(error)
      errors.add(:base, error.message)
    end

    def to_h
      attributes = {}
      self.class.columns_list.each do |column|
        attributes[column] = send(column) if respond_to?(column)
      end
      attributes
    end
end

class ErrorCollection
  def initialize
    @errors = Hash.new { |hash, key| hash[key] = [] }
  end

  def add(attribute, message)
    @errors[attribute] << message
  end

  def [](attribute)
    @errors[attribute]
  end

  def clear
    @errors.clear
  end

  def empty?
    @errors.empty?
  end

  def full_messages
    @errors.flat_map { |attribute, messages| messages.map { |msg| "#{attribute.to_s.capitalize} #{msg}" } }
  end
end
