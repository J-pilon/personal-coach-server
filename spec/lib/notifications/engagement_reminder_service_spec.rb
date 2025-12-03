# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::EngagementReminderService do
  subject(:service) { described_class.new }

  describe '#notification_type' do
    it 'returns engagement_reminder' do
      expect(service.notification_type).to eq('engagement_reminder')
    end
  end

  describe '#notification_title' do
    it 'returns the expected title' do
      expect(service.notification_title).to eq('We Miss You! 🎯')
    end
  end

  describe '#notification_data' do
    it 'returns correct type and screen' do
      expect(service.notification_data).to eq({
                                                type: 'engagement_reminder',
                                                screen: 'home'
                                              })
    end
  end

  describe '#notification_body' do
    let(:profile) { create(:profile) }

    before do
      profile.notification_preference.update!(last_opened_app_at: 5.days.ago)
      service.instance_variable_set(:@profile, profile)
    end

    it 'includes days since last open' do
      expect(service.notification_body).to eq("It's been 5 days. Your goals are waiting!")
    end
  end

  describe 'DAYS_THRESHOLD' do
    it 'is set to 3 days' do
      expect(described_class::DAYS_THRESHOLD).to eq(3)
    end
  end

  describe '#days_since_last_open' do
    let(:profile) { create(:profile) }

    before do
      service.instance_variable_set(:@profile, profile)
    end

    context 'when user has opened the app recently' do
      before { profile.notification_preference.update!(last_opened_app_at: 2.days.ago) }

      it 'returns the number of days' do
        expect(service.send(:days_since_last_open)).to eq(2)
      end
    end

    context 'when user has never opened the app' do
      it 'returns 999 as fallback' do
        expect(service.send(:days_since_last_open)).to eq(999)
      end
    end

    context 'when user opened app long ago' do
      before { profile.notification_preference.update!(last_opened_app_at: 10.days.ago) }

      it 'returns the correct number of days' do
        expect(service.send(:days_since_last_open)).to eq(10)
      end
    end
  end
end
