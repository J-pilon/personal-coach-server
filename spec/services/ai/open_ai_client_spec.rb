# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::OpenAiClient do
  let(:api_key) { 'test-api-key' }
  let(:client) { described_class.new(api_key) }
  let(:mock_openai_client) { instance_double(OpenAI::Client) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(mock_openai_client)
  end

  describe '#chat_completion' do
    let(:prompt) { 'Test prompt' }
    let(:successful_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => '{"specific": "Test goal", "measurable": "Test metric"}'
            }
          }
        ]
      }
    end

    context 'when API call is successful' do
      before do
        allow(mock_openai_client).to receive(:chat).and_return(successful_response)
      end

      it 'returns parsed JSON response' do
        result = client.chat_completion(prompt)

        expect(result).to eq({
                               'specific' => 'Test goal',
                               'measurable' => 'Test metric'
                             })
      end

      it 'calls OpenAI with correct parameters' do
        expect(mock_openai_client).to receive(:chat).with(
          parameters: {
            model: 'gpt-4o',
            messages: [{ role: 'system', content: prompt }],
            temperature: 0.7,
            max_tokens: 1000
          }
        ).and_return(successful_response)

        client.chat_completion(prompt)
      end

      it 'accepts custom temperature and model' do
        expect(mock_openai_client).to receive(:chat).with(
          parameters: {
            model: 'gpt-3.5-turbo',
            messages: [{ role: 'system', content: prompt }],
            temperature: 0.5,
            max_tokens: 1000
          }
        ).and_return(successful_response)

        client.chat_completion(prompt, temperature: 0.5, model: 'gpt-3.5-turbo')
      end
    end

    context 'when response is not valid JSON' do
      let(:non_json_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => 'This is not JSON content'
              }
            }
          ]
        }
      end

      before do
        allow(mock_openai_client).to receive(:chat).and_return(non_json_response)
      end

      it 'returns content wrapped in hash' do
        result = client.chat_completion(prompt)

        expect(result).to eq({ content: 'This is not JSON content' })
      end
    end

    context 'when response is empty' do
      let(:empty_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => ''
              }
            }
          ]
        }
      end

      before do
        allow(mock_openai_client).to receive(:chat).and_return(empty_response)
      end

      it 'raises AiServiceError' do
        expect { client.chat_completion(prompt) }.to raise_error(
          Ai::OpenAiClient::AiServiceError,
          'Empty response from OpenAI API'
        )
      end
    end

    context 'when OpenAI API raises an error', :slow do
      it 'retries up to MAX_RETRIES times' do
        expect(mock_openai_client).to receive(:chat).at_least(3).times.and_raise(
          OpenAI::Error.new('API rate limit exceeded')
        )

        expect { client.chat_completion(prompt) }.to raise_error(
          Ai::OpenAiClient::AiServiceError,
          'OpenAI API error: API rate limit exceeded'
        )
      end
    end

    context 'when OpenAI API raises an error with backoff', :slow do
      it 'implements exponential backoff' do
        allow(mock_openai_client).to receive(:chat).and_raise(
          OpenAI::Error.new('API rate limit exceeded')
        )

        start_time = Time.current
        expect { client.chat_completion(prompt) }.to raise_error(Ai::OpenAiClient::AiServiceError)
        end_time = Time.current

        # Should take at least 2 + 4 = 6 seconds (exponential backoff)
        expect(end_time - start_time).to be >= 6
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(mock_openai_client).to receive(:chat).and_raise(
          StandardError.new('Unexpected error')
        )
      end

      it 'raises AiServiceError with error message' do
        expect { client.chat_completion(prompt) }.to raise_error(
          Ai::OpenAiClient::AiServiceError,
          'Unexpected error: Unexpected error'
        )
      end
    end

    context 'when API key is not provided' do
      before do
        allow(Rails.application.credentials).to receive(:openai_api_key).and_return('default-key')
        allow(OpenAI::Client).to receive(:new).with(access_token: 'default-key').and_return(mock_openai_client)
      end

      it 'uses default API key from credentials' do
        client_without_key = described_class.new
        allow(mock_openai_client).to receive(:chat).and_return(successful_response)

        result = client_without_key.chat_completion(prompt)
        expect(result).to be_present
      end
    end
  end
end
