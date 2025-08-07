# frozen_string_literal: true

class AiServiceJob < AiProcessingJob
  def perform(profile_id, input, user_provided_key = nil, request_id = nil)
    Rails.logger.info "AiServiceJob#perform called with profile_id: #{profile_id}, input: #{input}"
    profile = Profile.find(profile_id)
    ai_request ||= find_or_create_ai_request(profile, input, request_id)

    begin
      result = process_ai_request(profile, input, user_provided_key)
      update_ai_request_status(ai_request, 'completed')
      result
    rescue StandardError => e
      Rails.logger.info "AiServiceJob#perform caught error: #{e.message}"
      handle_error(e, ai_request, profile_id, input, request_id)
    end
  end

  private

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
    Rails.logger.info "AiServiceJob#handle_error re-raising error"
    raise error
  end
end
