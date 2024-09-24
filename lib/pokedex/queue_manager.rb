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
      @priority_queue.pop(true) rescue @regular_queue.pop(true) rescue nil
    end
  end
end