# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe AiProcessingJob, type: :job do
  let(:profile) { create(:profile) }
  let(:ai_request) { create(:ai_request, profile: profile) }
  let(:job) { described_class.new }

  before do
    Sidekiq::Testing.inline!
    allow(Rails.logger).to receive(:error)
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#log_error' do
    it 'logs error with context' do
      error = StandardError.new('Test error')
      context = { profile_id: profile.id }

      job.send(:log_error, error, context)

      expect(Rails.logger).to have_received(:error).with('AI Processing Job Error: Test error')
      expect(Rails.logger).to have_received(:error).with("Context: #{context}")
      expect(Rails.logger).to have_received(:error).with(/Backtrace:/)
    end
  end

  describe '#update_ai_request_status' do
    it 'updates ai request status successfully' do
      expect(ai_request.status).to eq('pending')

      job.send(:update_ai_request_status, ai_request, 'completed', 'Test error')

      ai_request.reload
      expect(ai_request.status).to eq('completed')
      expect(ai_request.error_message).to eq('Test error')
      expect(ai_request.completed_at).to be_present
    end

    it 'handles update errors gracefully' do
      allow(ai_request).to receive(:update).and_raise(StandardError, 'Update failed')

      job.send(:update_ai_request_status, ai_request, 'completed')

      expect(Rails.logger).to have_received(:error).with('Failed to update AI request status: Update failed')
    end
  end
end
