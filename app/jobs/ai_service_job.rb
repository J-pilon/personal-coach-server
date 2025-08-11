# frozen_string_literal: true

class AiServiceJob < AiProcessingJob
  attr_reader :profile, :input, :timeframe, :intent, :user_provided_key, :request_id, :ai_request

  def perform(profile_id:, input:, intent:, **options)
    @timeframe = options[:timeframe]
    @user_provided_key = options[:user_provided_key]
    @request_id = options[:request_id]

    Rails.logger.info "AiServiceJob#perform called with profile_id: #{profile_id}, input: #{input}, " \
                      "timeframe: #{@timeframe}, job_id: #{@jid}"

    @profile = Profile.find(profile_id)
    @input = input
    @intent = intent
    @ai_request = find_or_create_ai_request

    process_with_status_update
  end

  private

  def process_with_status_update
    result = process_ai_request

    store(status: 'complete', progress: 100, result: result.to_json)

    update_ai_request_status(ai_request, 'completed')
    result
  rescue StandardError => e
    Rails.logger.info "AiServiceJob#perform caught error: #{e.message}"
    store(status: 'failed', progress: 0)
    handle_error(e)
  end

  def find_or_create_ai_request
    return AiRequest.find(request_id) if request_id

    AiRequest.create_with_prompt(
      profile_id: profile.id,
      prompt: input,
      job_type: 'smart_goal',
      status: 'pending'
    )
  end

  def process_ai_request
    service = Ai::AiService.new(profile: profile, user_provided_key: user_provided_key, intent: intent)
    service.process(input, timeframe)
  end

  def handle_error(error)
    Rails.logger.info "AiServiceJob#handle_error called with error: #{error.message}"
    log_error(error, { profile_id: profile.id, input: input, request_id: request_id })
    update_ai_request_status(ai_request, 'failed', error.message) if ai_request
    Rails.logger.info 'AiServiceJob#handle_error re-raising error'
    raise error
  end
end
