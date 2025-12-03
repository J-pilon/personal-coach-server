# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Notification flow integration' do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:profile) { user.profile }

  before do
    # Ensure notification preference exists and is properly configured
    profile.notification_preference.update!(
      push_enabled: true,
      timezone: 'UTC',
      preferred_time: Time.current.in_time_zone('UTC').beginning_of_hour
    )

    # Create an active device token
    create(:device_token, profile: profile, platform: 'ios', active: true)

    # Reload profile to ensure associations are fresh
    profile.reload
  end

  describe 'Daily Reminder flow' do
    describe 'ScheduleDailyRemindersJob -> DailyReminderJob -> DailyReminderService' do
      context 'when profile is eligible and time matches' do
        before { stub_expo_push_success }

        it 'schedules and executes daily reminder through full flow' do
          expect do
            perform_enqueued_jobs do
              Notifications::ScheduleDailyRemindersJob.perform_now
            end
          end.to change(Notification, :count).by(1)

          notification = Notification.last
          expect(notification).to have_attributes(
            profile: profile,
            notification_type: 'daily_reminder',
            channel: 'push',
            status: 'sent'
          )
          expect(notification.title).to start_with('Stay on Track!')
          expect(notification.sent_at).to be_present
        end

        it 'calls the Expo push API via HttpClientService' do
          mock_client = stub_expo_push_success

          perform_enqueued_jobs do
            Notifications::ScheduleDailyRemindersJob.perform_now
          end

          expect(mock_client).to have_received(:post).once
        end
      end

      context 'when profile notification time does not match current hour' do
        before do
          profile.notification_preference.update!(preferred_time: 3.hours.from_now)
        end

        it 'does not enqueue DailyReminderJob' do
          expect do
            Notifications::ScheduleDailyRemindersJob.perform_now
          end.not_to have_enqueued_job(Notifications::DailyReminderJob)
        end
      end

      context 'when push notifications are disabled' do
        before do
          profile.notification_preference.update!(push_enabled: false)
        end

        it 'does not enqueue DailyReminderJob' do
          expect do
            Notifications::ScheduleDailyRemindersJob.perform_now
          end.not_to have_enqueued_job(Notifications::DailyReminderJob)
        end
      end

      context 'when device token is inactive' do
        before do
          profile.device_tokens.each { |device_token| device_token.update!(active: false) }
        end

        it 'does not enqueue DailyReminderJob' do
          expect do
            Notifications::ScheduleDailyRemindersJob.perform_now
          end.not_to have_enqueued_job(Notifications::DailyReminderJob)
        end
      end
    end

    describe 'DailyReminderJob directly' do
      before { stub_expo_push_success }

      it 'sends notification to profile' do
        expect do
          Notifications::DailyReminderJob.perform_now(profile.id)
        end.to change(Notification, :count).by(1)

        expect(Notification.last.status).to eq('sent')
      end

      it 'handles missing profile gracefully' do
        expect do
          Notifications::DailyReminderJob.perform_now(-1)
        end.not_to raise_error
      end
    end
  end

  describe 'Engagement Reminder flow' do
    describe 'ScheduleEngagementRemindersJob -> EngagementReminderService' do
      context 'when profile has been inactive for threshold days' do
        before do
          stub_expo_push_success
          profile.notification_preference.update!(last_opened_app_at: 5.days.ago)
        end

        it 'sends engagement reminder' do
          expect do
            Notifications::ScheduleEngagementRemindersJob.perform_now
          end.to change(Notification, :count).by(1)

          notification = Notification.last
          expect(notification).to have_attributes(
            profile: profile,
            notification_type: 'engagement_reminder',
            channel: 'push',
            status: 'sent'
          )
        end
      end

      context 'when profile has been active recently' do
        before do
          profile.notification_preference.update!(last_opened_app_at: 1.day.ago)
        end

        it 'does not send engagement reminder' do
          expect do
            Notifications::ScheduleEngagementRemindersJob.perform_now
          end.not_to change(Notification, :count)
        end
      end

      context 'when profile has never opened the app' do
        before do
          stub_expo_push_success
          profile.notification_preference.update!(last_opened_app_at: nil)
        end

        it 'sends engagement reminder' do
          expect do
            Notifications::ScheduleEngagementRemindersJob.perform_now
          end.to change(Notification, :count).by(1)
        end
      end
    end
  end

  describe 'Multi-device support' do
    before do
      stub_expo_push_success
      # Add a second device
      create(:device_token, profile: profile, platform: 'android', active: true)
      profile.reload
    end

    it 'sends notification to all active devices' do
      expect do
        Notifications::DailyReminderJob.perform_now(profile.id)
      end.to change(Notification, :count).by(2)

      notifications = Notification.last(2)
      expect(notifications.map { |n| n.device_token.platform }).to contain_exactly('ios', 'android')
    end
  end

  describe 'Error handling' do
    context 'when Expo returns DeviceNotRegistered error' do
      before { stub_expo_push_device_not_registered }

      it 'deactivates the device token' do
        device_token = profile.device_tokens.active.first

        expect do
          Notifications::DailyReminderJob.perform_now(profile.id)
        end.to change { device_token.reload.active }.from(true).to(false)
      end

      it 'still marks notification as sent (Expo returned 200)' do
        Notifications::DailyReminderJob.perform_now(profile.id)

        expect(Notification.last.status).to eq('sent')
      end
    end

    context 'when Expo API returns HTTP error' do
      before { stub_expo_push_http_failure }

      it 'marks notification as failed' do
        Notifications::DailyReminderJob.perform_now(profile.id)

        notification = Notification.last
        expect(notification.status).to eq('failed')
        expect(notification.error_message).to be_present
      end
    end
  end

  describe 'Quiet hours' do
    before do
      stub_expo_push_success
      current_hour = Time.current.in_time_zone('UTC').hour
      profile.notification_preference.update!(
        quiet_hours_start: Time.zone.parse("#{current_hour}:00"),
        quiet_hours_end: Time.zone.parse("#{(current_hour + 2) % 24}:00")
      )
    end

    it 'does not send notifications during quiet hours' do
      expect do
        Notifications::DailyReminderService.new(profile).call
      end.not_to change(Notification, :count)
    end
  end
end
