# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::TaskReminderService do
  subject(:service) { described_class.new(profile, task: task) }

  let(:profile) { create(:profile) }
  let(:task) { create(:task, profile: profile, title: 'Submit Q2 report') }

  describe '#notification_type' do
    it 'returns task_reminder' do
      expect(service.notification_type).to eq('task_reminder')
    end
  end

  describe '#notification_title' do
    it 'returns a generic due-today title' do
      expect(service.notification_title).to eq('Task due today 📌')
    end
  end

  describe '#notification_body' do
    it 'returns the task title' do
      expect(service.notification_body).to eq('Submit Q2 report')
    end
  end

  describe '#notification_data' do
    it 'includes the task_id and routing metadata' do
      expect(service.notification_data).to eq({
                                                type: 'task_reminder',
                                                screen: 'taskDetail',
                                                task_id: task.id
                                              })
    end
  end
end
