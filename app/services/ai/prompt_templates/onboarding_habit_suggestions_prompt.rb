# frozen_string_literal: true

module Ai
  module PromptTemplates
    class OnboardingHabitSuggestionsPrompt
      MIN_MINUTES = 2
      NORMAL_MINUTES = 20
      ALLOWED_FREQUENCIES = %w[daily weekdays weekly_n_times custom].freeze

      def initialize(smart_goal:, exclude: [], position: nil)
        @smart_goal = smart_goal
        @exclude = exclude || []
        @position = position
      end

      def build
        <<~PROMPT
          You are a coach proposing small, ownable habits that support ONE primary goal.

          Methodology:
          - Propose, do not author. The user will edit and must approve every habit.
          - Favor small over ambitious. These should feel achievable on a bad day.
          - Each habit's cue MUST be tied to an existing daily routine the user already has
            (e.g. "after morning coffee", "right after brushing teeth"). If no routine is known,
            fall back to a generic anchor like "when I sit down at my desk".

          Constraints per habit:
          - `minimum_version` must be doable in under #{MIN_MINUTES} minutes.
          - `normal_version` must be doable in under #{NORMAL_MINUTES} minutes.
          - `frequency` must be one of: #{ALLOWED_FREQUENCIES.join(', ')}.
          - `frequency_config` is a JSON object; for `weekly_n_times` include
            `{"times_per_week": <int 1..6>}`. For `daily`/`weekdays` use `{}`.

          Primary goal:
          #{goal_block}

          #{scope_instruction}

          #{exclude_block}

          Banned content:
          - No shame or guilt language, no "streak" threats, no medical claims,
            no financial advice, no diagnosis. Server will strip banned content and
            treat the response as failed if any is present.

          Output STRICT JSON. No prose, no markdown fences. Shape:
          {
            "habits": [
              {
                "title": "<short imperative title>",
                "frequency": "<one of the allowed frequencies>",
                "frequency_config": { ... },
                "cue": "<routine-anchored cue>",
                "minimum_version": "<under #{MIN_MINUTES} min description>",
                "normal_version": "<under #{NORMAL_MINUTES} min description>"
              }
              // exactly #{expected_count} objects
            ]
          }
        PROMPT
      end

      private

      attr_reader :smart_goal, :exclude, :position

      def expected_count
        position ? 1 : 3
      end

      def scope_instruction
        if position
          "Return exactly 1 habit intended for position #{position}. This is a replacement " \
            'for a habit the user swapped out.'
        else
          'Return exactly 3 habits, ordered from most foundational (position 1) to most ambitious (position 3).'
        end
      end

      def exclude_block
        return 'No excluded titles.' if exclude.empty?

        list = exclude.map { |t| "- #{t}" }.join("\n")
        "Do NOT propose habits with these titles (already rejected):\n#{list}"
      end

      def goal_block
        return '(missing goal)' if smart_goal.blank?

        <<~GOAL
          - title: #{smart_goal.title}
          - why: #{smart_goal.try(:why)}
          - specific: #{smart_goal.specific}
          - measurable: #{smart_goal.measurable}
          - time_bound: #{smart_goal.time_bound}
          - target_date: #{smart_goal.target_date}
          - timeframe: #{smart_goal.timeframe}
        GOAL
      end
    end
  end
end
