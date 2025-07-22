# frozen_string_literal: true

module Ai
  class AiService
    def initialize(profile_id)
      @profile_id = profile_id
      @intent_router = IntentRouter.new('')
      @context_compressor = ContextCompressor.new(profile_id)
      @open_ai_client = OpenAiClient.new
    end

    def process(input)
      begin
        # Route the intent
        intent = IntentRouter.new(input).route

        # Compress user context
        context = @context_compressor.compress

        # Build appropriate prompt
        prompt = build_prompt(intent, input, context)

        # Create pending AiRequest record
        ai_request = AiRequest.create_with_prompt(
          profile_id: @profile_id,
          prompt: prompt,
          job_type: intent.to_s,
          status: 'pending'
        )

        # Call OpenAI API
        response = @open_ai_client.chat_completion(prompt)

        # Update with success
        ai_request.update(
          status: 'completed'
        )

        {
          intent: intent,
          response: response,
          context_used: context.present?,
          request_id: ai_request.id
        }
      rescue StandardError => e
        # Update existing AiRequest with failure or create new one if it doesn't exist
        ai_request = update_or_create_error_ai_request(ai_request, input, e.message)

        Rails.logger.error "AI Service error: #{e.message}"
        {
          intent: :error,
          response: { error: e.message },
          context_used: false,
          request_id: ai_request.id
        }
      end
    end

    private

    attr_reader :profile_id

    def update_or_create_error_ai_request(ai_request, input, error_message)
      if ai_request
        # Update existing AiRequest with failure
        ai_request.update(
          status: 'failed',
          error_message: error_message
        )
        ai_request
      else
        # Create new AiRequest for error case
        AiRequest.create_with_prompt(
          profile_id: @profile_id,
          prompt: input,
          job_type: 'unknown',
          status: 'failed'
        ).tap do |new_ai_request|
          new_ai_request.update(error_message: error_message)
        end
      end
    end

    def build_prompt(intent, input, context)
      case intent
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
