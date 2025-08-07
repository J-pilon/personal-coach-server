# frozen_string_literal: true

class TaskSuggestionJob < AiProcessingJob
  def perform(profile_id, user_provided_key = nil, request_id = nil)
    profile = Profile.find(profile_id)
    ai_request ||= find_or_create_ai_request(profile, request_id)

    begin
      result = process_task_suggestions(profile)
      update_ai_request_status(ai_request, 'completed')
      result
    rescue StandardError => e
      handle_error(e, ai_request, profile_id, request_id)
    end
  end

  private

  def find_or_create_ai_request(profile, request_id)
    return AiRequest.find(request_id) if request_id

    AiRequest.create_with_prompt(
      profile_id: profile.id,
      prompt: 'Task suggestions generation',
      job_type: 'task_suggestion',
      status: 'pending'
    )
  end

  def process_task_suggestions(profile)
    suggester = Ai::TaskSuggester.new(profile)
    suggester.generate_suggestions
  end

  def handle_error(error, ai_request, profile_id, request_id)
    log_error(error, { profile_id: profile_id, request_id: request_id })
    update_ai_request_status(ai_request, 'failed', error.message) if ai_request
    raise error
  end
end
