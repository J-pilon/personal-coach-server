# frozen_string_literal: true

module Ai
  module PromptTemplates
    # Prompt template for generating AI task suggestions
    class TaskSuggestionPrompt
      def initialize(context)
        @context = context
      end

      def build
        <<~PROMPT
          You are a productivity assistant helping a user generate relevant daily tasks based on their current goals and incomplete tasks.

          ## User Context:
          Work Role: #{@context[:user_context][:work_role]}
          Desires: #{@context[:user_context][:desires]}
          Limiting Beliefs: #{@context[:user_context][:limiting_beliefs]}

          ## Current Incomplete Tasks (Priority Order):
          #{format_incomplete_tasks}

          ## Active SMART Goals:
          #{format_active_goals}

          ## Instructions:
          Based on the user's context, incomplete tasks, and active goals, suggest exactly 3 new tasks that would be valuable for today.

          Each task should be:
          - Actionable and specific
          - Time-bound (with realistic time estimates)
          - Relevant to their current goals or incomplete tasks
          - Different from existing incomplete tasks
          - Appropriate for their work role and desires

          ## Response Format:
          Return ONLY a JSON array with exactly 3 task objects. Each object must have these fields:
          - title: A clear, actionable task title
          - description: Brief explanation of why this task is valuable
          - goal_id: ID of the related SMART goal (if applicable, otherwise null)
          - time_estimate_minutes: Realistic time estimate in minutes (15-120 minutes)

          Example response:
          [
            {
              "title": "Update portfolio README with recent projects",
              "description": "This will help showcase your latest work and align with your career advancement goals",
              "goal_id": "123",
              "time_estimate_minutes": 45
            }
          ]

          ## Important:
          - Return ONLY valid JSON
          - Include exactly 3 tasks
          - Ensure all fields are present
          - Make tasks specific and actionable
          - Consider the user's work role and current task load
        PROMPT
      end

      private

      def format_incomplete_tasks
        return 'No incomplete tasks found.' if @context[:incomplete_tasks].empty?

        @context[:incomplete_tasks].map do |task|
          "- #{task.title} (Priority: #{task.priority || 'Not set'})"
        end.join("\n")
      end

      def format_active_goals
        return 'No active goals found.' if @context[:active_goals].empty?

        @context[:active_goals].map do |goal|
          "- #{goal.title} (#{goal.timeframe_display}): #{goal.specific}"
        end.join("\n")
      end
    end
  end
end
