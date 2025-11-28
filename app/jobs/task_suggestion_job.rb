# frozen_string_literal: true

class TaskSuggestionJob < AiProcessingJob
  attr_reader :profile, :ai_request, :request_id, :user_provided_key

  def perform(profile_id:, user_provided_key: nil, request_id: nil)
    @profile = Profile.find(profile_id)
    @user_provided_key = user_provided_key
    @request_id = request_id
    @ai_request = find_or_create_ai_request

    process_with_status_update
  end

  private

  def process_with_status_update
    suggestions = process_task_suggestions

    result = {
      intent: 'task_suggestions',
      response: suggestions
    }

    store(status: 'complete', progress: 100, result: result.to_json)

    update_ai_request_status(ai_request, 'completed')
    result
  rescue StandardError => e
    # Store failure status
    store(status: 'failed', progress: 0)
    handle_error(e)
  end

  def find_or_create_ai_request
    return AiRequest.find(request_id) if request_id

    AiRequest.create_with_prompt(
      profile_id: profile.id,
      prompt: 'Task suggestions generation',
      job_type: 'task_suggestion',
      status: 'pending'
    )
  end

  def process_task_suggestions
    suggester = Ai::TaskSuggester.new(profile)
    suggester.generate_suggestions
  end

  def handle_error(error)
    log_error(error, { profile_id: profile.id, request_id: request_id })
    update_ai_request_status(ai_request, 'failed', error.message) if ai_request
    raise error
  end
end
