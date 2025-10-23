# frozen_string_literal: true

module Ai
  module PromptTemplates
    class SingleSmartGoalPrompt
      def initialize(user_input, timeframe, context = '')
        @user_input = user_input
        @timeframe = timeframe
        @context = context
      end

      def build
        <<~PROMPT
          You are an expert personal coach specializing in SMART goal creation. Your task is to transform the user's input into a well-structured SMART goal for the specified time period.

          SMART goals must be:
          - Specific: Clear and unambiguous
          - Measurable: Quantifiable progress indicators
          - Achievable: Realistic and attainable
          - Relevant: Aligned with broader objectives
          - Time-bound: Clear deadlines and timeframes

          User Context:
          #{context_section}

          User Input: "#{user_input}"
          Timeframe: #{processed_timeframe}

          Instructions:
          1. Analyze the user's input, context, and timeframe
          2. Create ONE SMART goal that addresses their needs for the specified timeframe
          3. The goal should be challenging but realistic for the given period
          4. Consider the user's existing goals and tasks when creating this goal
          5. Return ONLY a JSON object with the following structure:

          {
            "specific": "Clear, specific description of what will be accomplished",
            "measurable": "How progress will be measured and tracked",
            "achievable": "Why this goal is realistic and attainable in the given timeframe",
            "relevant": "How this goal aligns with broader objectives",
            "time_bound": "Specific timeline and deadlines for the #{processed_timeframe} period"
          }

          Ensure each component is detailed, actionable, and follows SMART principles. The goal should be appropriate for the #{processed_timeframe} timeframe and build toward the user's broader objective. Do not include any explanatory text outside the JSON structure.
        PROMPT
      end

      private

      attr_reader :user_input, :timeframe, :context

      def context_section
        return 'No additional context provided.' if context.blank?

        "Recent Goals and Tasks:\n#{context}"
      end

      def processed_timeframe
        timeframe || '1 month'
      end
    end
  end
end
