# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationPreference, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
  end

  describe '#in_quiet_hours?' do
    let(:profile) { create(:profile, timezone: 'UTC') }
    let(:preference) { profile.notification_preference }

    context 'when quiet hours are not set' do
      it 'returns false' do
        preference.quiet_hours_start = nil
        preference.quiet_hours_end = nil
        expect(preference.in_quiet_hours?).to be false
      end
    end

    context 'with normal quiet hours (e.g., 22:00-08:00 overnight)' do
      before do
        preference.quiet_hours_start = Time.zone.parse('22:00')
        preference.quiet_hours_end = Time.zone.parse('08:00')
      end

      it 'returns true during quiet hours (late night)' do
        time = Time.zone.parse('23:30')
        expect(preference.in_quiet_hours?(time)).to be true
      end

      it 'returns true during quiet hours (early morning)' do
        time = Time.zone.parse('06:00')
        expect(preference.in_quiet_hours?(time)).to be true
      end

      it 'returns false outside quiet hours' do
        time = Time.zone.parse('12:00')
        expect(preference.in_quiet_hours?(time)).to be false
      end
    end

    context 'with daytime quiet hours (e.g., 09:00-17:00)' do
      before do
        preference.quiet_hours_start = Time.zone.parse('09:00')
        preference.quiet_hours_end = Time.zone.parse('17:00')
      end

      it 'returns true during quiet hours' do
        time = Time.zone.parse('12:00')
        expect(preference.in_quiet_hours?(time)).to be true
      end

      it 'returns false outside quiet hours' do
        time = Time.zone.parse('20:00')
        expect(preference.in_quiet_hours?(time)).to be false
      end
    end
  end
end
