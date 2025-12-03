# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::EngagementReminderJob, type: :job do
  let(:profile) { create(:profile) }

  before do
    Sidekiq::Testing.inline!
    allow(Rails.logger).to receive(:warn)
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    context 'when profile exists' do
      it 'calls EngagementReminderService with the profile' do
        mock_service = instance_double(Notifications::EngagementReminderService)
        allow(Notifications::EngagementReminderService).to receive(:new)
          .with(profile)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)

        described_class.perform_now(profile.id)

        expect(Notifications::EngagementReminderService).to have_received(:new).with(profile)
        expect(mock_service).to have_received(:call)
      end
    end

    context 'when profile is not found' do
      it 'logs a warning and does not raise an error' do
        expect do
          described_class.perform_now(999_999)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn)
          .with(/EngagementReminderJob: Profile not found: 999999/)
      end
    end
  end

  describe 'queue configuration' do
    it 'uses the notifications queue' do
      expect(described_class.queue_name).to eq('notifications')
    end

    it 'has retry configuration' do
      expect(described_class).to respond_to(:retry_on)
    end
  end
end
