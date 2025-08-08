# frozen_string_literal: true

class AiServiceJob < AiProcessingJob
  def perform(profile_id, input, user_provided_key = nil, request_id = nil)
    Rails.logger.info "AiServiceJob#perform called with profile_id: #{profile_id}, input: #{input}, job_id: #{@jid}"
    profile = Profile.find(profile_id)
    ai_request ||= find_or_create_ai_request(profile, input, request_id)

    process_with_status_update(ai_request, profile, input, user_provided_key)
  end

  private

  def process_with_status_update(ai_request, profile, input, user_provided_key)
    result = process_ai_request(profile, input, user_provided_key)

    # Store the result in Sidekiq status for polling
    store(status: 'complete', progress: 100, result: result)

    update_ai_request_status(ai_request, 'completed')
    result
  rescue StandardError => e
    Rails.logger.info "AiServiceJob#perform caught error: #{e.message}"
    # Store failure status
    store(status: 'failed', progress: 0)
    handle_error(e, ai_request, profile.id, input, nil)
  end

  def find_or_create_ai_request(profile, input, request_id)
    return AiRequest.find(request_id) if request_id

    AiRequest.create_with_prompt(
      profile_id: profile.id,
      prompt: input,
      job_type: 'smart_goal',
      status: 'pending'
    )
  end

  def process_ai_request(profile, input, user_provided_key)
    service = Ai::AiService.new(profile, user_provided_key)
    service.process(input)
  end

  def handle_error(error, ai_request, profile_id, input, request_id)
    Rails.logger.info "AiServiceJob#handle_error called with error: #{error.message}"
    log_error(error, { profile_id: profile_id, input: input, request_id: request_id })
    update_ai_request_status(ai_request, 'failed', error.message) if ai_request
    Rails.logger.info 'AiServiceJob#handle_error re-raising error'
    raise error
  end
end
