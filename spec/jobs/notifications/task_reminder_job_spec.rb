# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::TaskReminderJob, type: :job do
  let(:profile) { create(:profile) }
  let(:task) { create(:task, profile: profile) }

  before do
    Sidekiq::Testing.inline!
    allow(Rails.logger).to receive(:warn)
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    context 'when the task exists and is not completed' do
      it 'calls TaskReminderService with the profile and task' do
        mock_service = instance_double(Notifications::TaskReminderService)
        allow(Notifications::TaskReminderService).to receive(:new)
          .with(profile, task: task)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)

        described_class.perform_now(task.id)

        expect(Notifications::TaskReminderService).to have_received(:new).with(profile, task: task)
        expect(mock_service).to have_received(:call)
      end
    end

    context 'when the task is already completed' do
      it 'does not call the service' do
        task.update!(completed: true)
        allow(Notifications::TaskReminderService).to receive(:new)

        described_class.perform_now(task.id)

        expect(Notifications::TaskReminderService).not_to have_received(:new)
      end
    end

    context 'when the task is not found' do
      it 'logs a warning and does not raise' do
        expect do
          described_class.perform_now(999_999)
        end.not_to raise_error

        expect(Rails.logger).to have_received(:warn)
          .with(/TaskReminderJob: Task not found: 999999/)
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
