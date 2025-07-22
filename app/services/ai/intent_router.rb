# frozen_string_literal: true

module Ai
  class IntentRouter
    GOAL_KEYWORDS = %w[goal objective target aim achieve accomplish reach].freeze
    PRIORITIZATION_KEYWORDS = %w[prioritize priority order rank sort organize arrange].freeze
    TASK_KEYWORDS = %w[task todo item action step].freeze

    def initialize(input)
      @input = input.to_s.downcase.strip
    end

    def route
      if goal_intent?
        :smart_goal
      elsif prioritization_intent?
        :prioritization
      else
        raise "IntentRouter: '#{input}' input does not match accepted choices."
      end
    end

    private

    attr_reader :input

    def goal_intent?
      GOAL_KEYWORDS.any? { |keyword| input.include?(keyword) } ||
        input.match?(/\b(create|make|set|establish|define)\s+(a\s+)?(goal|objective|target)/)
    end

    def prioritization_intent?
      (PRIORITIZATION_KEYWORDS.any? { |keyword| input.include?(keyword) } ||
       TASK_KEYWORDS.any? { |keyword| input.include?(keyword) }) &&
        input.match?(/\b(list|tasks|todo|items|actions)\b/)
    end
  end
end
