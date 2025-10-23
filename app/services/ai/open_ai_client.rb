# frozen_string_literal: true

module Ai
  class OpenAiClient
    MAX_RETRIES = 3
    DEFAULT_TEMPERATURE = 0.7
    DEFAULT_MODEL = 'gpt-4o'

    def initialize(api_key = nil)
      @api_key = api_key || Rails.application.credentials.openai[:api_key]
      @client = OpenAI::Client.new(access_token: @api_key)
    end

    def chat_completion(prompt, temperature: DEFAULT_TEMPERATURE, model: DEFAULT_MODEL)
      retries = 0

      begin
        response = @client.chat(
          parameters: {
            model: model,
            messages: [{ role: 'system', content: prompt }],
            temperature: temperature,
            max_tokens: 1000
          }
        )

        parse_response(response)
      rescue OpenAI::Error => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn "OpenAI API error (attempt #{retries}): #{e.message}"
          sleep(2**retries)
          retry
        else
          Rails.logger.error "OpenAI API failed after #{MAX_RETRIES} attempts: #{e.message}"
          raise AiServiceError, "OpenAI API error: #{e.message}"
        end
      rescue AiServiceError
        # Re-raise AiServiceError without wrapping
        raise
      rescue StandardError => e
        Rails.logger.error "Unexpected error in OpenAI client: #{e.message}"
        raise AiServiceError, "Unexpected error: #{e.message}"
      end
    end

    private

    def parse_response(response)
      content = response.dig('choices', 0, 'message', 'content')

      raise AiServiceError, 'Empty response from OpenAI API' if content.blank?

      # Try to parse as JSON first
      begin
        JSON.parse(content)
      rescue JSON::ParserError
        extract_json_from_markdown(content) || { content: content }
      end
    end

    def extract_json_from_markdown(content)
      return nil unless content.include?('```json')

      json_match = content.match(/```json\s*\n(.*?)\n```/m)
      return nil unless json_match

      JSON.parse(json_match[1])
    rescue JSON::ParserError
      nil
    end

    class AiServiceError < StandardError; end
  end
end
