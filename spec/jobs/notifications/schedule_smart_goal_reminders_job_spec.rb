# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::ScheduleSmartGoalRemindersJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  before do
    Sidekiq::Testing.fake!
    Sidekiq::Queues.clear_all
    travel_to Time.zone.local(2026, 5, 25, 10, 0, 0)
  end

  let(:profile) do
    profile = create(:profile, timezone: 'UTC')
    profile.notification_preference.update!(push_enabled: true)
    create(:device_token, profile: profile, active: true)
    profile
  end

  describe '#perform' do
    context 'when a smart goal target_date is today and reminder hour has been reached' do
      it 'enqueues a SmartGoalReminderJob for the goal' do
        goal = create(:smart_goal, profile: profile, completed: false,
                                   target_date: Time.zone.local(2026, 5, 25, 15, 0, 0),
                                   reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::SmartGoalReminderJob).with(goal.id)
      end
    end

    context "when the goal's reminder hour has not been reached yet" do
      it 'does not enqueue a SmartGoalReminderJob' do
        create(:smart_goal, profile: profile, completed: false,
                            target_date: Time.zone.local(2026, 5, 25, 15, 0, 0),
                            reminder_at: '14:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::SmartGoalReminderJob)
      end
    end

    context 'when the goal is completed' do
      it 'does not enqueue a SmartGoalReminderJob' do
        create(:smart_goal, profile: profile, completed: true,
                            target_date: Time.zone.local(2026, 5, 25, 15, 0, 0),
                            reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::SmartGoalReminderJob)
      end
    end

    context "when the goal's target_date is tomorrow" do
      it 'does not enqueue a SmartGoalReminderJob' do
        create(:smart_goal, profile: profile, completed: false,
                            target_date: Time.zone.local(2026, 5, 26, 12, 0, 0),
                            reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::SmartGoalReminderJob)
      end
    end

    context 'when a smart_goal_reminder has already been sent for this goal today' do
      it 'does not enqueue a SmartGoalReminderJob' do
        goal = create(:smart_goal, profile: profile, completed: false,
                                   target_date: Time.zone.local(2026, 5, 25, 15, 0, 0),
                                   reminder_at: '09:00:00')
        Notification.create!(
          profile: profile,
          notification_type: 'smart_goal_reminder',
          channel: 'push',
          title: 'Goal target date today 🎯',
          body: goal.title,
          data: { smart_goal_id: goal.id },
          status: 'sent',
          scheduled_for: Time.zone.local(2026, 5, 25, 9, 0, 0)
        )

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::SmartGoalReminderJob)
      end
    end

    context 'when the profile is not push-eligible' do
      it 'does not enqueue a SmartGoalReminderJob' do
        ineligible = create(:profile, timezone: 'UTC')
        ineligible.notification_preference.update!(push_enabled: false)
        create(:smart_goal, profile: ineligible, completed: false,
                            target_date: Time.zone.local(2026, 5, 25, 15, 0, 0),
                            reminder_at: '09:00:00')

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::SmartGoalReminderJob)
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
