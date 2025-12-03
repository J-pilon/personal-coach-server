# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe Notifications::ScheduleEngagementRemindersJob, type: :job do
  before do
    Sidekiq::Testing.inline!
  end

  after do
    Sidekiq::Testing.fake!
  end

  describe '#perform' do
    context 'when profile is eligible and inactive for 3+ days' do
      it 'calls EngagementReminderService for the profile' do
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          last_opened_app_at: 4.days.ago
        )
        create(:device_token, profile: profile, active: true)

        mock_service = instance_double(Notifications::EngagementReminderService)
        allow(Notifications::EngagementReminderService).to receive(:new)
          .with(profile)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)

        described_class.perform_now

        expect(Notifications::EngagementReminderService).to have_received(:new).with(profile)
        expect(mock_service).to have_received(:call)
      end
    end

    context 'when profile has been active within 3 days' do
      it 'does not call EngagementReminderService' do
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          last_opened_app_at: 1.day.ago
        )
        create(:device_token, profile: profile, active: true)

        expect(Notifications::EngagementReminderService).not_to receive(:new)

        described_class.perform_now
      end
    end

    context 'when profile does not have push enabled' do
      it 'does not call EngagementReminderService' do
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: false,
          last_opened_app_at: 4.days.ago
        )
        create(:device_token, profile: profile, active: true)

        expect(Notifications::EngagementReminderService).not_to receive(:new)

        described_class.perform_now
      end
    end

    context 'when profile does not have active device tokens' do
      it 'does not call EngagementReminderService' do
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          last_opened_app_at: 4.days.ago
        )
        create(:device_token, profile: profile, active: false)

        expect(Notifications::EngagementReminderService).not_to receive(:new)

        described_class.perform_now
      end
    end

    context 'when profile has never opened the app' do
      it 'calls EngagementReminderService (nil last_opened_app_at)' do
        profile = create(:profile)
        profile.notification_preference.update!(
          push_enabled: true,
          last_opened_app_at: nil
        )
        create(:device_token, profile: profile, active: true)

        mock_service = instance_double(Notifications::EngagementReminderService)
        allow(Notifications::EngagementReminderService).to receive(:new)
          .with(profile)
          .and_return(mock_service)
        allow(mock_service).to receive(:call)

        described_class.perform_now

        expect(Notifications::EngagementReminderService).to have_received(:new).with(profile)
        expect(mock_service).to have_received(:call)
      end
    end

    context 'with multiple eligible profiles' do
      it 'calls EngagementReminderService for all matching profiles' do
        profile1 = create(:profile)
        profile1.notification_preference.update!(
          push_enabled: true,
          last_opened_app_at: 5.days.ago
        )
        create(:device_token, profile: profile1, active: true)

        profile2 = create(:profile)
        profile2.notification_preference.update!(
          push_enabled: true,
          last_opened_app_at: 10.days.ago
        )
        create(:device_token, profile: profile2, active: true)

        mock_service1 = instance_double(Notifications::EngagementReminderService)
        mock_service2 = instance_double(Notifications::EngagementReminderService)

        allow(Notifications::EngagementReminderService).to receive(:new)
          .with(profile1)
          .and_return(mock_service1)
        allow(Notifications::EngagementReminderService).to receive(:new)
          .with(profile2)
          .and_return(mock_service2)
        allow(mock_service1).to receive(:call)
        allow(mock_service2).to receive(:call)

        described_class.perform_now

        expect(mock_service1).to have_received(:call)
        expect(mock_service2).to have_received(:call)
      end
    end
  end

  describe 'queue configuration' do
    it 'uses the critical queue' do
      expect(described_class.queue_name).to eq('critical')
    end
  end

  describe 'constants' do
    it 'defines INACTIVE_DAYS_THRESHOLD from service' do
      expect(described_class::INACTIVE_DAYS_THRESHOLD).to eq(3)
    end
  end
end
