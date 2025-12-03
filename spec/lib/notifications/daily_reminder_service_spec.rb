# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::DailyReminderService do
  let(:profile) { create(:profile) }

  subject(:service) { described_class.new(profile) }

  describe '#notification_type' do
    it 'returns daily_reminder' do
      expect(service.notification_type).to eq('daily_reminder')
    end
  end

  describe '#notification_title' do
    it 'returns the expected title' do
      expect(service.notification_title).to eq('Stay on Track! 💪')
    end
  end

  describe '#notification_body' do
    it 'returns the expected body' do
      expect(service.notification_body).to eq("Can't accomplish your goal by not chipping away at it day by day")
    end
  end

  describe '#notification_data' do
    it 'returns correct type and screen' do
      expect(service.notification_data).to eq({
                                                type: 'daily_reminder',
                                                screen: 'tasks'
                                              })
    end
  end
end
