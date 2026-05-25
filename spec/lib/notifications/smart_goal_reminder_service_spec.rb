# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::SmartGoalReminderService do
  subject(:service) { described_class.new(profile, smart_goal: smart_goal) }

  let(:profile) { create(:profile) }
  let(:smart_goal) { create(:smart_goal, profile: profile, title: 'Run a marathon') }

  describe '#notification_type' do
    it 'returns smart_goal_reminder' do
      expect(service.notification_type).to eq('smart_goal_reminder')
    end
  end

  describe '#notification_title' do
    it 'returns a generic target-date title' do
      expect(service.notification_title).to eq('Goal target date today 🎯')
    end
  end

  describe '#notification_body' do
    it 'returns the smart goal title' do
      expect(service.notification_body).to eq('Run a marathon')
    end
  end

  describe '#notification_data' do
    it 'includes the smart_goal_id and routing metadata' do
      expect(service.notification_data).to eq({
                                                type: 'smart_goal_reminder',
                                                screen: 'smartGoalDetail',
                                                smart_goal_id: smart_goal.id
                                              })
    end
  end
end
