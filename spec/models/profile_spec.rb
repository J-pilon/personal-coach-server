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

      it 'excludes profiles whose device tokens are all stale' do
        profile = create(:profile)
        profile.notification_preference.update!(push_enabled: true)
        create(:device_token, :stale, profile: profile, active: true)

        expect(described_class.push_notification_eligible).not_to include(profile)
      end

      it 'includes profiles with at least one fresh active device token' do
        profile = create(:profile)
        profile.notification_preference.update!(push_enabled: true)
        create(:device_token, :stale, profile: profile, active: true)
        create(:device_token, profile: profile, active: true, last_used_at: 1.day.ago)

        expect(described_class.push_notification_eligible).to include(profile)
      end
    end

    describe '.inactive_for_days' do
      it 'returns profiles whose last_opened_app_at is older than the threshold' do
        inactive_profile = create(:profile)
        inactive_profile.notification_preference.update!(last_opened_app_at: 5.days.ago)

        active_profile = create(:profile)
        active_profile.notification_preference.update!(last_opened_app_at: 1.day.ago)

        test_profiles = [inactive_profile, active_profile]
        result = described_class.where(id: test_profiles.map(&:id)).inactive_for_days(3)
        expect(result).to contain_exactly(inactive_profile)
      end

      it 'treats never-opened profiles whose account is older than the threshold as inactive' do
        old_unopened = create(:profile)
        old_unopened.notification_preference.update!(last_opened_app_at: nil)
        # rubocop:disable Rails/SkipsModelValidations
        old_unopened.update_column(:created_at, 5.days.ago)
        # rubocop:enable Rails/SkipsModelValidations

        result = described_class.where(id: old_unopened.id).inactive_for_days(3)
        expect(result).to contain_exactly(old_unopened)
      end

      it 'does not return never-opened profiles whose account is younger than the threshold' do
        new_unopened = create(:profile)
        new_unopened.notification_preference.update!(last_opened_app_at: nil)

        result = described_class.where(id: new_unopened.id).inactive_for_days(3)
        expect(result).to be_empty
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
        expect(profile.notification_preference.reload.last_opened_app_at)
          .to be_within(1.second).of(Time.current)
      end

      it 'is a no-op if last_opened_app_at was set within the throttle window' do
        recent = 1.minute.ago
        profile.notification_preference.update!(last_opened_app_at: recent)

        profile.record_app_open!

        expect(profile.notification_preference.reload.last_opened_app_at)
          .to be_within(1.second).of(recent)
      end

      it 'updates when last_opened_app_at is older than the throttle window' do
        profile.notification_preference.update!(last_opened_app_at: 10.minutes.ago)

        profile.record_app_open!

        expect(profile.notification_preference.reload.last_opened_app_at)
          .to be_within(1.second).of(Time.current)
      end
    end
  end
end
