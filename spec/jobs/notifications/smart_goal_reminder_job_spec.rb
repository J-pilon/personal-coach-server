# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::SmartGoalReminderJob, type: :job do
  let(:profile) { create(:profile) }
  let(:smart_goal) { create(:smart_goal, profile: profile) }

  before do
    Sidekiq::Testing.inline!
    allow(Rails.logger).to receive(:warn)
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    context 'when the smart goal exists and is not completed' do
      it 'calls SmartGoalReminderService with the profile and smart goal' do
        mock_service = instance_double(Notifications::SmartGoalReminderService)
        allow(Notifications::SmartGoalReminderService).to receive(:new)
          .with(profile, smart_goal: smart_goal)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)

        described_class.perform_now(smart_goal.id)

        expect(Notifications::SmartGoalReminderService).to have_received(:new).with(profile, smart_goal: smart_goal)
        expect(mock_service).to have_received(:call)
      end
    end

    context 'when the smart goal is already completed' do
      it 'does not call the service' do
        smart_goal.update!(completed: true)
        allow(Notifications::SmartGoalReminderService).to receive(:new)

        described_class.perform_now(smart_goal.id)

        expect(Notifications::SmartGoalReminderService).not_to have_received(:new)
      end
    end

    context 'when the smart goal is not found' do
      it 'logs a warning and does not raise' do
        expect do
          described_class.perform_now(999_999)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn)
          .with(/SmartGoalReminderJob: SmartGoal not found: 999999/)
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
