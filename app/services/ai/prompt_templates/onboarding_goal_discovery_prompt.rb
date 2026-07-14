# frozen_string_literal: true

module Ai
  module PromptTemplates
    class OnboardingGoalDiscoveryPrompt
      MIN_DAYS_AHEAD = 7

      def initialize(messages:, force_draft: false)
        @messages = messages || []
        @force_draft = force_draft
      end

      def build
        <<~PROMPT
          You are a coach helping the user articulate ONE meaningful goal for the next few months.

          Methodology:
          - Propose, do not author. The user must approve every artifact you produce.
          - Ask ONE short discovery question at a time (max ~25 words).
          - Aim to uncover: what they want, why it matters to them personally, a realistic timeframe,
            and what success would look like.
          - Use the user's own words whenever possible. Never invent specifics they did not state.

          After 4-6 questions you should return a SMART goal draft.
          #{force_draft_instruction}

          Target date rule: `target_date` MUST be at least #{MIN_DAYS_AHEAD} days after today. Never
          propose a target date before today + #{MIN_DAYS_AHEAD} days. If your best guess would be
          earlier, clamp to today + #{MIN_DAYS_AHEAD} days.

          Output STRICT JSON. Exactly one of these two shapes, no prose, no markdown fences:

          Shape A - a question to the user:
          { "kind": "question", "text": "<your next single question>" }

          Shape B - a SMART goal draft for the user to approve:
          {
            "kind": "smart_goal_draft",
            "goal": {
              "title": "<short title in the user's words>",
              "why": "<why this matters to the user, in their words>",
              "specific": "<clear, specific description>",
              "measurable": "<how progress will be measured>",
              "time_bound": "<explicit timeline/deadline language>",
              "target_date": "<YYYY-MM-DD, at least today + #{MIN_DAYS_AHEAD} days>",
              "timeframe": "<one of: 1_month | 3_months | 6_months>"
            }
          }

          Do NOT include any keys other than those listed. Do NOT wrap the JSON in markdown.

          Conversation so far:
          #{formatted_transcript}
        PROMPT
      end

      private

      attr_reader :messages, :force_draft

      def force_draft_instruction
        if force_draft
          'The turn cap has been reached. You MUST return Shape B (smart_goal_draft) on this turn. ' \
            'Do not ask another question.'
        else
          'If you have enough to draft, prefer Shape B (smart_goal_draft); otherwise return Shape A (question).'
        end
      end

      def formatted_transcript
        return '(no messages yet - open with your first discovery question)' if messages.empty?

        messages.map do |m|
          role = m['role'] || m[:role]
          text = m['text'] || m[:text]
          "#{role}: #{text}"
        end.join("\n")
      end
    end
  end
end
