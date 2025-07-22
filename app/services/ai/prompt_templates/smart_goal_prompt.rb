# frozen_string_literal: true

module Ai
  module PromptTemplates
    class SmartGoalPrompt
      def initialize(user_input, context = '')
        @user_input = user_input
        @context = context
      end

      def build
        <<~PROMPT
          You are an expert personal coach specializing in SMART goal creation. Your task is to transform the user's input into a well-structured SMART goal.

          SMART goals must be:
          - Specific: Clear and unambiguous
          - Measurable: Quantifiable progress indicators
          - Achievable: Realistic and attainable
          - Relevant: Aligned with broader objectives
          - Time-bound: Clear deadlines and timeframes

          User Context:
          #{context_section}

          User Input: "#{user_input}"

          Instructions:
          1. Analyze the user's input and context
          2. Create a SMART goal that addresses their needs
          3. Return ONLY a JSON object with the following structure:
          {
            "specific": "Clear, specific description of what will be accomplished",
            "measurable": "How progress will be measured and tracked",
            "achievable": "Why this goal is realistic and attainable",
            "relevant": "How this goal aligns with broader objectives",
            "time_bound": "Specific timeline and deadlines"
          }

          Ensure each component is detailed, actionable, and follows SMART principles. Do not include any explanatory text outside the JSON structure.
        PROMPT
      end

      private

      attr_reader :user_input, :context

      def context_section
        return 'No additional context provided.' if context.blank?

        "Recent Goals and Tasks:\n#{context}"
      end
    end
  end
end
