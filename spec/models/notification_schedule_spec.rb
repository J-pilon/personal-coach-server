# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSchedule, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
  end

  describe 'validations' do
    subject { build(:notification_schedule) }

    it { is_expected.to validate_presence_of(:local_time) }
    it { is_expected.to validate_presence_of(:timezone) }

    it 'rejects unknown kinds' do
      schedule = build(:notification_schedule, kind: 'weekly_wrap')
      expect(schedule).not_to be_valid
      expect(schedule.errors[:kind]).to be_present
    end

    it 'rejects unknown IANA timezones' do
      schedule = build(:notification_schedule, timezone: 'Mars/Olympus')
      expect(schedule).not_to be_valid
      expect(schedule.errors[:timezone]).to be_present
    end
  end

  describe 'partial unique index on (profile_id, kind) where active' do
    let(:profile) { create(:profile) }

    it 'rejects a second active row for the same (profile, kind)' do
      create(:notification_schedule, profile: profile)

      expect {
        create(:notification_schedule, profile: profile)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows a new active row when the earlier one is inactive' do
      create(:notification_schedule, :inactive, profile: profile)

      expect {
        create(:notification_schedule, profile: profile)
      }.not_to raise_error
    end

    it 'allows multiple inactive rows for the same (profile, kind)' do
      create(:notification_schedule, :inactive, profile: profile)

      expect {
        create(:notification_schedule, :inactive, profile: profile)
      }.not_to raise_error
    end
  end
end
