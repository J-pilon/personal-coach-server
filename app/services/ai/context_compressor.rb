# frozen_string_literal: true

module Ai
  class ContextCompressor
    MAX_TOKENS = 1000
    MAX_GOALS = 3
    MAX_TASKS = 5

    def initialize(user_id)
      @user_id = user_id
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

    attr_reader :user_id

    def recent_goals_context
      goals = user.profile.smart_goals
                  .pending
                  .order(created_at: :desc)
                  .limit(MAX_GOALS)

      return nil if goals.empty?

      goals_text = goals.map do |goal|
        "Goal: #{goal.title}\n" \
        "Specific: #{goal.specific}\n" \
        "Timeframe: #{goal.timeframe_display}"
      end.join("\n\n")

      "Current Goals:\n#{goals_text}"
    end

    def recent_tasks_context
      tasks = user.profile.tasks
                  .where(completed: false)
                  .order(created_at: :desc)
                  .limit(MAX_TASKS)

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
        context[0...max_chars] + "\n\n[Context truncated for length]"
      else
        context
      end
    end

    def user
      @user ||= User.find(user_id)
    end
  end
end
