# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::ScheduleTaskRemindersJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  before do
    Sidekiq::Testing.fake!
    Sidekiq::Queues.clear_all
    travel_to Time.zone.local(2026, 5, 25, 10, 0, 0) # 10:00 UTC on a fixed date
  end

  let(:profile) do
    profile = create(:profile, timezone: 'UTC')
    profile.notification_preference.update!(push_enabled: true)
    create(:device_token, profile: profile, active: true)
    profile
  end

  describe '#perform' do
    context 'when a task is due today and reminder hour has been reached' do
      it 'enqueues a TaskReminderJob for the task' do
        task = create(:task, profile: profile, completed: false,
                             due_at: Time.zone.local(2026, 5, 25, 15, 0, 0),
                             reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::TaskReminderJob).with(task.id)
      end
    end

    context "when the task's reminder hour has not been reached yet" do
      it 'does not enqueue a TaskReminderJob' do
        create(:task, profile: profile, completed: false,
                      due_at: Time.zone.local(2026, 5, 25, 15, 0, 0),
                      reminder_at: '14:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::TaskReminderJob)
      end
    end

    context 'when the task is completed' do
      it 'does not enqueue a TaskReminderJob' do
        create(:task, profile: profile, completed: true,
                      due_at: Time.zone.local(2026, 5, 25, 15, 0, 0),
                      reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::TaskReminderJob)
      end
    end

    context 'when the task is due tomorrow' do
      it 'does not enqueue a TaskReminderJob' do
        create(:task, profile: profile, completed: false,
                      due_at: Time.zone.local(2026, 5, 26, 12, 0, 0),
                      reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::TaskReminderJob)
      end
    end

    context 'when the task is overdue (due yesterday)' do
      it 'does not enqueue a TaskReminderJob' do
        create(:task, profile: profile, completed: false,
                      due_at: Time.zone.local(2026, 5, 24, 12, 0, 0),
                      reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::TaskReminderJob)
      end
    end

    context 'when a task_reminder has already been sent for this task today' do
      it 'does not enqueue a TaskReminderJob' do
        task = create(:task, profile: profile, completed: false,
                             due_at: Time.zone.local(2026, 5, 25, 15, 0, 0),
                             reminder_at: '09:00:00')
        Notification.create!(
          profile: profile,
          notification_type: 'task_reminder',
          channel: 'push',
          title: 'Task due today 📌',
          body: task.title,
          data: { task_id: task.id },
          status: 'sent',
          scheduled_for: Time.zone.local(2026, 5, 25, 9, 0, 0)
        )

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::TaskReminderJob)
      end
    end

    context 'when the profile is not push-eligible' do
      it 'does not enqueue a TaskReminderJob' do
        ineligible = create(:profile, timezone: 'UTC')
        ineligible.notification_preference.update!(push_enabled: false)
        create(:task, profile: ineligible, completed: false,
                      due_at: Time.zone.local(2026, 5, 25, 15, 0, 0),
                      reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::TaskReminderJob)
      end
    end

    context 'with multiple due tasks for one profile' do
      it 'enqueues a job for each task' do
        create(:task, profile: profile, completed: false,
                      due_at: Time.zone.local(2026, 5, 25, 12, 0, 0),
                      reminder_at: '09:00:00')
        create(:task, profile: profile, completed: false,
                      due_at: Time.zone.local(2026, 5, 25, 18, 0, 0),
                      reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::TaskReminderJob).exactly(2).times
      end
    end
  end

  describe 'queue configuration' do
    it 'uses the critical queue' do
      expect(described_class.queue_name).to eq('critical')
    end

    it 'has retry configuration' do
      expect(described_class).to respond_to(:retry_on)
    end
  end
end
