# frozen_string_literal: true

module Pokedex
  class QueueManager
    def initialize
      @regular_queue = Queue.new
      @priority_queue = Queue.new
    end

    def enqueue_priority(element)
      @priority_queue.push(element)
    end

    def enqueue_all(elements)
      elements.each { |element| @regular_queue.push(element) }
    end

    def next_in_queue
      begin
        @priority_queue.pop(true)
      rescue StandardError
        @regular_queue.pop(true)
      end
    rescue StandardError
      nil
    end
  end
end
