# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::ScheduleDailyRemindersJob, type: :job do
  before do
    Sidekiq::Testing.fake!
    Sidekiq::Queues.clear_all
  end

  describe '#perform' do
    context 'when profile is eligible and time matches' do
      it 'enqueues DailyReminderJob for the profile' do
        current_hour = Time.current.in_time_zone('UTC').hour
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          timezone: 'UTC',
          preferred_time: Time.zone.parse("#{current_hour}:00")
        )
        create(:device_token, profile: profile, active: true)

        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::DailyReminderJob).with(profile.id)
      end
    end

    context 'when preferred time does not match current hour' do
      it 'does not enqueue DailyReminderJob' do
        current_hour = Time.current.in_time_zone('UTC').hour
        different_hour = (current_hour + 2) % 24
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          timezone: 'UTC',
          preferred_time: Time.zone.parse("#{different_hour}:00")
        )
        create(:device_token, profile: profile, active: true)

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DailyReminderJob)
      end
    end

    context 'when profile does not have push enabled' do
      it 'does not enqueue DailyReminderJob' do
        current_hour = Time.current.in_time_zone('UTC').hour
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: false,
          timezone: 'UTC',
          preferred_time: Time.zone.parse("#{current_hour}:00")
        )
        create(:device_token, profile: profile, active: true)

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DailyReminderJob)
      end
    end

    context 'when profile does not have active device tokens' do
      it 'does not enqueue DailyReminderJob' do
        current_hour = Time.current.in_time_zone('UTC').hour
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          timezone: 'UTC',
          preferred_time: Time.zone.parse("#{current_hour}:00")
        )
        create(:device_token, profile: profile, active: false)

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DailyReminderJob)
      end
    end

    context 'with multiple eligible profiles' do
      it 'enqueues jobs for all matching profiles' do
        current_hour = Time.current.in_time_zone('UTC').hour

        profile1 = create(:profile)
        profile1.notification_preference.update!(
          push_enabled: true,
          timezone: 'UTC',
          preferred_time: Time.zone.parse("#{current_hour}:00")
        )
        create(:device_token, profile: profile1, active: true)

        profile2 = create(:profile)
        profile2.notification_preference.update!(
          push_enabled: true,
          timezone: 'UTC',
          preferred_time: Time.zone.parse("#{current_hour}:00")
        )
        create(:device_token, profile: profile2, active: true)

        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::DailyReminderJob).exactly(2).times
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
