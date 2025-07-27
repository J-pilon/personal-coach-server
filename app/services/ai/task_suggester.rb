# frozen_string_literal: true

module Ai
  # Service for generating AI-powered task suggestions based on user context
  class TaskSuggester
    def initialize(profile)
      @profile = profile
      @open_ai_client = OpenAiClient.new
    end

    def generate_suggestions
      context = build_context
      prompt = build_prompt(context)
      ai_request = create_ai_request(prompt)

      begin
        response = @open_ai_client.chat_completion(
          prompt,
          temperature: 0.6,
          model: 'gpt-4o'
        )

        ai_request.update(status: 'completed')
        parse_suggestions(response)
      rescue StandardError => e
        ai_request.update(status: 'failed', error_message: e.message)
        raise e
      end
    end

    private

    attr_reader :profile

    def build_context
      {
        incomplete_tasks: profile.tasks.incomplete.order(priority: :desc).limit(10),
        active_goals: profile.smart_goals.pending,
        user_context: {
          work_role: profile.work_role,
          desires: profile.desires,
          limiting_beliefs: profile.limiting_beliefs
        }
      }
    end

    def build_prompt(context)
      PromptTemplates::TaskSuggestionPrompt.new(context).build
    end

    def create_ai_request(prompt)
      AiRequest.create_with_prompt(
        profile_id: profile.id,
        prompt: prompt,
        job_type: 'task_suggestion',
        status: 'pending'
      )
    end

    def parse_suggestions(response)
      suggestions = extract_suggestions_array(response)
      suggestions.map { |suggestion| structure_suggestion(suggestion) }
    rescue StandardError => e
      Rails.logger.error "Failed to parse AI suggestions: #{e.message}"
      Rails.logger.error "Raw response: #{response}"
      raise AiServiceError, "Failed to parse AI suggestions: #{e.message}"
    end

    def extract_suggestions_array(response)
      response.is_a?(Array) ? response : response['suggestions'] || []
    end

    def structure_suggestion(suggestion)
      {
        title: suggestion['title'] || suggestion[:title],
        description: suggestion['description'] || suggestion[:description] || '',
        goal_id: suggestion['goal_id'] || suggestion[:goal_id],
        time_estimate_minutes: suggestion['time_estimate_minutes'] || suggestion[:time_estimate_minutes] || 30
      }
    end

    class AiServiceError < StandardError; end
  end
end
