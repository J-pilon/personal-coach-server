# frozen_string_literal: true

module Ai
  class AiService
    def initialize(profile:, intent:, user_provided_key: nil)
      @profile = profile
      @user_provided_key = user_provided_key
      @intent = intent
      @open_ai_client = OpenAiClient.new(user_provided_key)
    end

    def process(input)
      ai_request = nil
      begin
        context = compress_context
        prompt = build_prompt(input, context)
        ai_request = create_ai_request(prompt)
        response = open_ai_client.chat_completion(prompt)

        handle_success(response, context, ai_request)
      rescue StandardError => e
        handle_error(e, ai_request)
      end
    end

    private

    attr_reader :profile, :user_provided_key, :intent, :open_ai_client

    def compress_context
      ContextCompressor.perform(profile)
    end

    def create_ai_request(prompt)
      AiRequest.create_with_prompt(
        profile_id: profile.id,
        prompt: prompt,
        job_type: intent.to_s,
        status: 'pending'
      )
    end

    def handle_success(response, context, ai_request)
      ai_request.update(status: 'completed')

      build_success_response(response, context, ai_request.id)
    end

    def build_success_response(response, context, request_id)
      {
        intent: intent,
        response: response,
        context_used: context.present?,
        request_id: request_id
      }
    end

    def handle_error(error, ai_request)
      if ai_request
        ai_request.update(
          status: 'failed',
          error_message: error.message
        )
        request_id = ai_request.id
      else
        request_id = nil
      end

      build_error_response(error, request_id)
    end

    def build_error_response(error, request_id)
      Rails.logger.error "AI Service error: #{error.message}"
      {
        intent: :error,
        response: { error: error.message },
        context_used: false,
        request_id: request_id
      }
    end

    def build_prompt(input, context)
      case intent.to_sym
      when :smart_goal
        PromptTemplates::SmartGoalPrompt.new(input, context).build
      when :prioritization
        PromptTemplates::PrioritizationPrompt.new(input, context).build
      else
        raise "Unknown intent: #{intent}"
      end
    end
  end
end
