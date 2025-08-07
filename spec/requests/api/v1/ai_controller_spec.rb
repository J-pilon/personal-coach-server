# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::AiController', type: :request do
  let(:user) { create(:user) }
  let(:profile) { user.profile }

  before do
    Rails.cache.clear
    sign_in user
  end

  describe 'POST /api/v1/ai/proxy' do
    context 'with valid input' do
      let(:valid_params) { { input: 'Create a SMART goal for learning React Native' } }

      it 'processes AI request successfully' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(AiServiceJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/proxy', params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response).to include('message', 'job_id', 'status', 'usage_info')
        expect(json_response['message']).to eq('AI request queued for processing')
        expect(json_response['status']).to eq('queued')
        expect(json_response['job_id']).to eq('job-123')
      end

      it 'includes usage info in response' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(AiServiceJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/proxy', params: valid_params

        json_response = response.parsed_body
        usage_info = json_response['usage_info']
        expect(usage_info).to include('using_own_key', 'remaining')
      end
    end

    context 'with user provided API key' do
      let(:valid_params) do
        {
          input: 'Create a SMART goal for learning React Native',
          user_provided_key: 'sk-test-user-key'
        }
      end

      it 'processes request without rate limiting' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(AiServiceJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/proxy', params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        usage_info = json_response['usage_info']
        expect(usage_info['using_own_key']).to be true
      end
    end

    context 'with missing input' do
      it 'returns bad request error' do
        post '/api/v1/ai/proxy', params: {}

        expect(response).to have_http_status(:bad_request)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Input is required')
      end
    end

    context 'when rate limit is exceeded' do
      before do
        # Mock the rate limiter to simulate exceeded limit
        rate_limiter = instance_double(Ai::RateLimiter)
        allow(Ai::RateLimiter).to receive(:new).and_return(rate_limiter)
        limit_message = 'You\'ve hit your 3-request AI limit.'
        allow(rate_limiter).to receive_messages(
          check_limit: {
            allowed: false,
            reason: 'daily_limit_exceeded',
            message: limit_message
          },
          record_request: nil,
          usage_info: {
            using_own_key: false,
            remaining: 0,
            total_limit: 3
          }
        )
      end

      it 'returns too many requests error' do
        post '/api/v1/ai/proxy', params: { input: 'Test input' }

        expect(response).to have_http_status(:too_many_requests)
        json_response = response.parsed_body
        expect(json_response['error']).to include('3-request AI limit')
        expect(json_response['reason']).to eq('daily_limit_exceeded')
      end
    end

    context 'when user has made some requests' do
      before do
        # Mock the rate limiter to simulate some requests made
        rate_limiter = instance_double(Ai::RateLimiter)
        allow(Ai::RateLimiter).to receive(:new).and_return(rate_limiter)
        allow(rate_limiter).to receive_messages(
          check_limit: {
            allowed: true,
            reason: nil,
            message: nil
          },
          record_request: nil,
          usage_info: {
            using_own_key: false,
            remaining: 2,
            total_limit: 3
          }
        )
      end

      it 'allows the request and shows remaining count' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(AiServiceJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/proxy', params: { input: 'Test input' }

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        usage_info = json_response['usage_info']
        expect(usage_info['remaining']).to eq(2)
      end
    end
  end

  describe 'POST /api/v1/ai/usage' do
    it 'returns usage information' do
      post '/api/v1/ai/usage'

      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body
      expect(json_response).to include('usage_info')
    end

    context 'when user has made some requests' do
      before do
        # Mock the rate limiter to simulate some requests made
        rate_limiter = instance_double(Ai::RateLimiter)
        allow(Ai::RateLimiter).to receive(:new).and_return(rate_limiter)
        allow(rate_limiter).to receive(:usage_info).and_return(
          using_own_key: false,
          remaining: 2,
          total_limit: 3
        )
      end

      it 'returns correct remaining count' do
        post '/api/v1/ai/usage'

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        usage_info = json_response['usage_info']
        expect(usage_info['remaining']).to eq(2)
      end
    end
  end

  describe 'POST /api/v1/ai' do
    # Test the original endpoint still works
    let(:valid_params) { { input: 'Create a SMART goal for learning React Native' } }

    it 'processes AI request successfully' do
      # Mock the job to return a job ID
      job = instance_double(ActiveJob::Base)
      allow(job).to receive(:provider_job_id).and_return('job-123')
      allow(AiServiceJob).to receive(:perform_later).and_return(job)

      post '/api/v1/ai', params: valid_params

      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body
      expect(json_response).to include('message', 'job_id', 'status')
      expect(json_response['message']).to eq('AI request queued for processing')
      expect(json_response['status']).to eq('queued')
      expect(json_response['job_id']).to eq('job-123')
    end
  end

  describe 'POST /api/v1/ai/suggested_tasks' do
    let(:valid_params) { { profile_id: profile.id } }

    context 'with valid request' do
      it 'generates task suggestions successfully' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(TaskSuggestionJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/suggested_tasks', params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        expect(json_response).to include('message', 'job_id', 'status', 'usage_info')
        expect(json_response['message']).to eq('Task suggestions queued for processing')
        expect(json_response['status']).to eq('queued')
        expect(json_response['job_id']).to eq('job-123')
      end

      it 'includes usage info in response' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(TaskSuggestionJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/suggested_tasks', params: valid_params

        json_response = response.parsed_body
        usage_info = json_response['usage_info']
        expect(usage_info).to include('using_own_key', 'remaining')
        expect(usage_info['remaining']).to eq(2) # Should have 2 remaining after this request
      end
    end

    context 'with user provided API key' do
      let(:valid_params) do
        {
          profile_id: profile.id,
          user_provided_key: 'sk-test-user-key'
        }
      end

      it 'processes request without rate limiting' do
        # Mock the job to return a job ID
        job = instance_double(ActiveJob::Base)
        allow(job).to receive(:provider_job_id).and_return('job-123')
        allow(TaskSuggestionJob).to receive(:perform_later).and_return(job)

        post '/api/v1/ai/suggested_tasks', params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body
        usage_info = json_response['usage_info']
        expect(usage_info['using_own_key']).to be true
      end
    end

    context 'when rate limit is exceeded' do
      before do
        # Mock the rate limiter to simulate exceeded limit
        rate_limiter = instance_double(Ai::RateLimiter)
        allow(Ai::RateLimiter).to receive(:new).and_return(rate_limiter)
        limit_message = 'You\'ve hit your 3-request AI limit.'
        allow(rate_limiter).to receive_messages(
          check_limit: {
            allowed: false,
            reason: 'daily_limit_exceeded',
            message: limit_message
          },
          record_request: nil,
          usage_info: {
            using_own_key: false,
            remaining: 0,
            total_limit: 3
          }
        )
      end

      it 'returns too many requests error' do
        post '/api/v1/ai/suggested_tasks', params: valid_params

        expect(response).to have_http_status(:too_many_requests)
        json_response = response.parsed_body
        expect(json_response['error']).to include('3-request AI limit')
        expect(json_response['reason']).to eq('daily_limit_exceeded')
      end
    end

    context 'when profile is not found' do
      it 'returns not found error' do
        post '/api/v1/ai/suggested_tasks', params: { profile_id: 99_999 }

        expect(response).to have_http_status(:not_found)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Profile not found')
      end
    end

    context 'when task suggester raises an error' do
      before do
        # Mock the job to raise an error when enqueued
        allow(TaskSuggestionJob).to receive(:perform_later).and_raise(StandardError, 'Task suggester error')
      end

      it 'returns internal server error' do
        post '/api/v1/ai/suggested_tasks', params: valid_params

        expect(response).to have_http_status(:internal_server_error)
        json_response = response.parsed_body
        expect(json_response['error']).to eq('Failed to generate task suggestions')
      end
    end
  end
end
