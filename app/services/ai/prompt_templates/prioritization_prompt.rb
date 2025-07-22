# frozen_string_literal: true

module Ai
  module PromptTemplates
    class PrioritizationPrompt
      def initialize(tasks_input, context = '')
        @tasks_input = tasks_input
        @context = context
      end

      def build
        <<~PROMPT
          You are an expert productivity coach specializing in task prioritization. Your task is to analyze the user's tasks and prioritize them based on their SMART goals and current context.

          Prioritization Criteria:
          - Urgency: Time-sensitive tasks that need immediate attention
          - Importance: Tasks that align with long-term goals and values
          - Impact: Tasks that create the most significant positive outcomes
          - Dependencies: Tasks that enable other important work
          - Energy: Tasks that match the user's current capacity and resources

          User Context:
          #{context_section}

          Tasks to Prioritize:
          #{tasks_input}

          Instructions:
          1. Analyze each task against the user's goals and context
          2. Assign a priority level (1-5, where 1 is highest priority)
          3. Provide a brief rationale for each priority level
          4. Return ONLY a JSON array with the following structure:
          [
            {
              "task": "Task description",
              "priority": 1-5,
              "rationale": "Brief explanation of priority level",
              "recommended_action": "do|defer|delegate"
            }
          ]

          Consider the user's current goals, available time, and energy levels when making recommendations. Do not include any explanatory text outside the JSON structure.
        PROMPT
      end

      private

      attr_reader :tasks_input, :context

      def context_section
        return 'No additional context provided.' if context.blank?

        "Current Goals and Recent Tasks:\n#{context}"
      end
    end
  end
end
