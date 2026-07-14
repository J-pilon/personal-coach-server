# frozen_string_literal: true

class OnboardingHabitSuggestionJob < AiProcessingJob
  class InvalidAiResponseError < StandardError; end

  HABIT_KEYS = %w[title frequency frequency_config cue minimum_version normal_version].freeze
  ALLOWED_FREQUENCIES = Ai::PromptTemplates::OnboardingHabitSuggestionsPrompt::ALLOWED_FREQUENCIES

  attr_reader :smart_goal, :ai_request, :exclude, :position

  def perform(smart_goal_id:, ai_request_id:, exclude: [], position: nil)
    @smart_goal = SmartGoal.find(smart_goal_id)
    @ai_request = AiRequest.find(ai_request_id)
    @exclude = exclude
    @position = position

    process_with_status_update
  end

  private

  def process_with_status_update
    result = generate_and_validate

    store(status: 'complete', progress: 100, result: result.to_json)
    update_ai_request_status(ai_request, 'completed')
    result
  rescue StandardError => e
    store(status: 'failed', progress: 0)
    handle_error(e)
  end

  def generate_and_validate
    prompt = Ai::PromptTemplates::OnboardingHabitSuggestionsPrompt.new(
      smart_goal: smart_goal,
      exclude: exclude,
      position: position
    ).build

    ai_request.update(prompt: prompt)

    raw = Ai::OpenAiClient.new.chat_completion(prompt)
    parsed = coerce_hash(raw)

    validate!(parsed)
    parsed
  end

  def coerce_hash(raw)
    case raw
    when Hash then raw.deep_stringify_keys
    when String then JSON.parse(raw)
    else raise InvalidAiResponseError, "unsupported response type: #{raw.class}"
    end
  rescue JSON::ParserError => e
    raise InvalidAiResponseError, "response is not valid JSON: #{e.message}"
  end

  def validate!(parsed)
    habits = parsed['habits']
    raise InvalidAiResponseError, 'habits missing' unless habits.is_a?(Array)

    expected = position ? 1 : 3
    raise InvalidAiResponseError, "expected #{expected} habits, got #{habits.size}" if habits.size != expected

    habits.each_with_index { |h, i| validate_habit!(h, i) }

    raise InvalidAiResponseError, 'banned content detected' if Ai::BannedContent.scan_deep(parsed)
  end

  def validate_habit!(habit, index)
    raise InvalidAiResponseError, "habit #{index} not an object" unless habit.is_a?(Hash)

    missing = HABIT_KEYS - habit.keys
    raise InvalidAiResponseError, "habit #{index} missing keys: #{missing}" if missing.any?

    unless ALLOWED_FREQUENCIES.include?(habit['frequency'])
      raise InvalidAiResponseError, "habit #{index} invalid frequency: #{habit['frequency'].inspect}"
    end

    return if habit['frequency_config'].is_a?(Hash)

    raise InvalidAiResponseError, "habit #{index} frequency_config not an object"
  end

  def handle_error(error)
    log_error(error, { smart_goal_id: smart_goal&.id, ai_request_id: ai_request&.id })
    update_ai_request_status(ai_request, 'failed', error.message) if ai_request
    raise error
  end
end
