# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::JobStatus', type: :request do
  let!(:user) { create(:user) }

  before { sign_in user }

  describe 'GET /api/v1/jobs/:id' do
    context 'when the job exists' do
      before do
        allow(JobStatusService).to receive(:get_status).with('job-abc').and_return(
          'status' => 'complete',
          'progress' => 100,
          'result' => '{"habits":[]}',
          'message' => nil,
          'updated_at' => Time.current.to_s
        )
      end

      it 'returns the job status' do
        get api_v1_job_status_path('job-abc')

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['job_id']).to eq('job-abc')
        expect(json['status']).to eq('complete')
      end
    end

    context 'when the job is not found' do
      before do
        allow(JobStatusService).to receive(:get_status).and_return(nil)
      end

      it 'returns a not found error with the standard error envelope' do
        get api_v1_job_status_path('nonexistent-job')

        expect(response).to have_http_status(:not_found)
        json = response.parsed_body
        expect(json['error']).to be_present
        expect(json['error']['code']).to eq('')
        expect(json['error']['message']).to eq('Job not found')
        expect(json['error']['details']).to be_nil
      end
    end

    context 'when the job status service raises an error' do
      before do
        allow(JobStatusService).to receive(:get_status).and_raise(StandardError, 'Redis connection failed')
      end

      it 'returns an internal server error with the standard error envelope' do
        get api_v1_job_status_path('job-abc')

        expect(response).to have_http_status(:internal_server_error)
        json = response.parsed_body
        expect(json['error']).to be_present
        expect(json['error']['code']).to eq('')
        expect(json['error']['message']).to eq('Failed to get job status')
        expect(json['error']['details']).to be_nil
      end
    end
  end
end
