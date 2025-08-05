# frozen_string_literal: true

module Ai
  class ContextCompressor
    MAX_TOKENS = 1000
    MAX_GOALS = 3
    MAX_TASKS = 5

    def self.perform(profile)
      instance = new(profile)
      instance.compress
    end

    def initialize(profile)
      @profile = profile
    end

    def compress
      goals_context = recent_goals_context
      tasks_context = recent_tasks_context

      combined_context = [goals_context, tasks_context].compact.join("\n\n")

      # Simple token estimation (roughly 4 characters per token)
      estimated_tokens = combined_context.length / 4

      if estimated_tokens > MAX_TOKENS
        truncate_context(combined_context)
      else
        combined_context
      end
    end

    private

    attr_reader :profile

    def recent_goals_context
      goals = find_pending_smart_goals

      return nil if goals.empty?

      goals_text = goals.map do |goal|
        "Goal: #{goal.title}\n" \
          "Specific: #{goal.specific}\n" \
          "Timeframe: #{goal.timeframe_display}"
      end.join("\n\n")

      "Current Goals:\n#{goals_text}"
    end

    def recent_tasks_context
      tasks = find_recent_incomplete_tasks

      return nil if tasks.empty?

      tasks_text = tasks.map do |task|
        "Task: #{task.title}\n" \
          "Category: #{task.action_category}\n" \
          "Status: #{task.completed? ? 'Completed' : 'Pending'}"
      end.join("\n\n")

      "Recent Tasks:\n#{tasks_text}"
    end

    def truncate_context(context)
      # Simple truncation to fit within token limit
      max_chars = (MAX_TOKENS * 4) - 50 # Leave room for truncation message
      if context.length > max_chars
        "#{context[0...max_chars]}\n\n[Context truncated for length]"
      else
        context
      end
    end

    def find_pending_smart_goals
      profile.pending_smart_goals(MAX_GOALS)
    end

    def find_recent_incomplete_tasks
      profile.recent_incomplete_tasks(MAX_TASKS)
    end
  end
end
