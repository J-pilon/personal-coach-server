# frozen_string_literal: true

class OnboardingDiscoveryJob < AiProcessingJob
  class InvalidAiResponseError < StandardError; end

  ALLOWED_TIMEFRAMES = %w[1_month 3_months 6_months].freeze
  GOAL_KEYS = %w[title why specific measurable time_bound target_date timeframe].freeze
  MIN_DAYS_AHEAD = Ai::PromptTemplates::OnboardingGoalDiscoveryPrompt::MIN_DAYS_AHEAD

  attr_reader :discovery_session, :ai_request, :force_draft

  def perform(discovery_session_id:, ai_request_id:, force_draft: false)
    @discovery_session = DiscoverySession.find(discovery_session_id)
    @ai_request = AiRequest.find(ai_request_id)
    @force_draft = force_draft

    process_with_status_update
  end

  private

  def process_with_status_update
    result = generate_and_validate

    apply_side_effects(result)

    store(status: 'complete', progress: 100, result: result.to_json)
    update_ai_request_status(ai_request, 'completed')
    result
  rescue StandardError => e
    store(status: 'failed', progress: 0)
    handle_error(e)
  end

  def generate_and_validate
    prompt = Ai::PromptTemplates::OnboardingGoalDiscoveryPrompt.new(
      messages: discovery_session.messages,
      force_draft: force_draft
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
    kind = parsed['kind']
    case kind
    when 'question' then validate_question!(parsed)
    when 'smart_goal_draft' then validate_draft!(parsed)
    else raise InvalidAiResponseError, "unexpected kind: #{kind.inspect}"
    end

    raise InvalidAiResponseError, 'banned content detected' if Ai::BannedContent.scan_deep(parsed)
  end

  def validate_question!(parsed)
    text = parsed['text']
    raise InvalidAiResponseError, 'question text missing' if text.blank?

    extras = parsed.keys - %w[kind text]
    raise InvalidAiResponseError, "unexpected keys: #{extras}" if extras.any?
    raise InvalidAiResponseError, 'question emitted after turn cap' if force_draft
  end

  def validate_draft!(parsed)
    goal = parsed['goal']
    raise InvalidAiResponseError, 'goal missing' unless goal.is_a?(Hash)

    missing = GOAL_KEYS - goal.keys
    raise InvalidAiResponseError, "missing goal keys: #{missing}" if missing.any?

    unless ALLOWED_TIMEFRAMES.include?(goal['timeframe'])
      raise InvalidAiResponseError, "invalid timeframe: #{goal['timeframe'].inspect}"
    end

    goal['target_date'] = clamp_target_date(goal['target_date'])

    extras = parsed.keys - %w[kind goal]
    raise InvalidAiResponseError, "unexpected top-level keys: #{extras}" if extras.any?
  end

  def clamp_target_date(raw)
    min = Date.current + MIN_DAYS_AHEAD
    parsed = Date.parse(raw.to_s)
    [parsed, min].max.iso8601
  rescue Date::Error, TypeError
    min.iso8601
  end

  def apply_side_effects(result)
    case result['kind']
    when 'question'
      discovery_session.append_message!(role: :assistant, text: result['text'])
      discovery_session.update!(turn_count: discovery_session.turn_count + 1)
    when 'smart_goal_draft'
      discovery_session.update!(status: 'drafted')
    end
  end

  def handle_error(error)
    log_error(error, { discovery_session_id: discovery_session&.id, ai_request_id: ai_request&.id })
    update_ai_request_status(ai_request, 'failed', error.message) if ai_request
    raise error
  end
end
