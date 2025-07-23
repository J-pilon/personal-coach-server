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
          You are an expert personal coach specializing in SMART goal creation. Your task is to transform the user's input into well-structured SMART goals for three different time periods.

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
          2. Create THREE SMART goals that address their needs across different timeframes:
             - 1 Month Goal: Short-term, immediate progress
             - 3 Month Goal: Medium-term, building momentum
             - 6 Month Goal: Long-term, significant achievement
          3. Each goal should be progressively more challenging but build upon the previous one
          4. Return ONLY a JSON object with the following structure:
          {
            "one_month": {
              "specific": "Clear, specific description of what will be accomplished in 1 month",
              "measurable": "How progress will be measured and tracked",
              "achievable": "Why this goal is realistic and attainable in 1 month",
              "relevant": "How this goal aligns with broader objectives",
              "time_bound": "Specific 1-month timeline and deadlines"
            },
            "three_months": {
              "specific": "Clear, specific description of what will be accomplished in 3 months",
              "measurable": "How progress will be measured and tracked",
              "achievable": "Why this goal is realistic and attainable in 3 months",
              "relevant": "How this goal aligns with broader objectives",
              "time_bound": "Specific 3-month timeline and deadlines"
            },
            "six_months": {
              "specific": "Clear, specific description of what will be accomplished in 6 months",
              "measurable": "How progress will be measured and tracked",
              "achievable": "Why this goal is realistic and attainable in 6 months",
              "relevant": "How this goal aligns with broader objectives",
              "time_bound": "Specific 6-month timeline and deadlines"
            }
          }

          Ensure each component is detailed, actionable, and follows SMART principles. The goals should form a logical progression where the 1-month goal builds toward the 3-month goal, and the 3-month goal builds toward the 6-month goal. Do not include any explanatory text outside the JSON structure.
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
