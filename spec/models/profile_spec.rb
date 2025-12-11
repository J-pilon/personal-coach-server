# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Profile, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:smart_goals).dependent(:destroy) }
    it { is_expected.to have_many(:tasks).dependent(:destroy) }
    it { is_expected.to have_many(:ai_requests).dependent(:destroy) }
    it { is_expected.to have_many(:tickets).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
    it { is_expected.to have_many(:device_tokens).dependent(:destroy) }
    it { is_expected.to have_one(:notification_preference).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:onboarding_status).in_array(%w[incomplete complete]) }

    it 'validates timezone inclusion' do
      expect(subject).to validate_inclusion_of(:timezone).in_array(
        %w[Pacific/Honolulu America/Anchorage America/Los_Angeles America/Denver America/Chicago America/New_York
           America/Halifax America/Sao_Paulo Atlantic/Reykjavik Europe/London Europe/Paris Europe/Berlin Europe/Moscow
           Asia/Dubai Asia/Kolkata Asia/Bangkok Asia/Singapore Asia/Hong_Kong Asia/Tokyo Australia/Sydney
           Pacific/Auckland UTC]
      )
    end
  end

  describe 'callbacks' do
    it 'creates notification_preference after create' do
      profile = create(:profile)
      expect(profile.notification_preference).to be_present
    end
  end

  describe 'scopes' do
    describe '.push_notification_eligible' do
      it 'returns profiles with push enabled and active devices' do
        eligible_profile = create(:profile)
        eligible_profile.notification_preference.update!(push_enabled: true)
        create(:device_token, profile: eligible_profile, active: true)

        ineligible_profile = create(:profile)
        ineligible_profile.notification_preference.update!(push_enabled: false)

        expect(described_class.push_notification_eligible).to contain_exactly(eligible_profile)
      end
    end

    describe '.inactive_for_days' do
      it 'returns profiles inactive for specified days or with nil last_opened_app_at' do
        inactive_profile = create(:profile)
        inactive_profile.notification_preference.update!(last_opened_app_at: 5.days.ago)

        active_profile = create(:profile)
        active_profile.notification_preference.update!(last_opened_app_at: 1.day.ago)

        never_opened_profile = create(:profile)
        never_opened_profile.notification_preference.update!(last_opened_app_at: nil)

        test_profiles = [inactive_profile, active_profile, never_opened_profile]
        result = described_class.where(id: test_profiles.map(&:id)).inactive_for_days(3)
        expect(result).to contain_exactly(inactive_profile, never_opened_profile)
      end
    end
  end

  describe 'instance methods' do
    let(:profile) { create(:profile, first_name: 'John', last_name: 'Doe') }

    describe '#onboarding_complete?' do
      it 'returns true when onboarding_status is complete' do
        profile.update!(onboarding_status: 'complete')
        expect(profile.onboarding_complete?).to be true
      end

      it 'returns false when onboarding_status is incomplete' do
        expect(profile.onboarding_complete?).to be false
      end
    end

    describe '#complete_onboarding!' do
      it 'updates status and sets completed_at timestamp' do
        profile.complete_onboarding!
        expect(profile.onboarding_status).to eq('complete')
        expect(profile.onboarding_completed_at).to be_within(1.second).of(Time.current)
      end
    end

    describe '#incomplete_tasks' do
      it 'returns only incomplete tasks' do
        incomplete = create(:task, profile: profile, completed: false)
        create(:task, profile: profile, completed: true)

        expect(profile.incomplete_tasks).to contain_exactly(incomplete)
      end
    end

    describe '#push_notifications_enabled?' do
      it 'returns true when push is enabled and push tokens exist' do
        profile.notification_preference.update!(push_enabled: true)
        create(:device_token, profile: profile, active: true, platform: 'ios')

        expect(profile.push_notifications_enabled?).to be true
      end

      it 'returns false when no active push tokens' do
        profile.notification_preference.update!(push_enabled: true)
        create(:device_token, profile: profile, active: false, platform: 'ios')

        expect(profile.push_notifications_enabled?).to be false
      end
    end

    describe '#record_app_open!' do
      it 'updates last_opened_app_at on notification_preference' do
        profile.record_app_open!
        expect(profile.notification_preference.last_opened_app_at).to be_within(1.second).of(Time.current)
      end
    end
  end
end
