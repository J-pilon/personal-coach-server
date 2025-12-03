# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:status).in_array(Notification::STATUSES) }
    it { is_expected.to validate_inclusion_of(:notification_type).in_array(Notification::TYPES) }
    it { is_expected.to validate_inclusion_of(:channel).in_array(Notification::CHANNELS) }
  end

  describe 'scopes' do
    let!(:pending_notification) { create(:notification, status: 'pending', channel: 'push') }
    let!(:sent_notification) { create(:notification, :sent, channel: 'push') }
    let!(:failed_notification) { create(:notification, :failed, channel: 'push') }
    let!(:email_notification) { create(:notification, :email, status: 'pending') }

    describe '.pending' do
      it 'returns only pending notifications' do
        expect(described_class.pending).to contain_exactly(pending_notification, email_notification)
      end
    end

    describe '.sent' do
      it 'returns only sent notifications' do
        expect(described_class.sent).to contain_exactly(sent_notification)
      end
    end

    describe '.failed' do
      it 'returns only failed notifications' do
        expect(described_class.failed).to contain_exactly(failed_notification)
      end
    end

    describe '.by_channel' do
      it 'returns notifications by channel' do
        expect(described_class.by_channel('email')).to contain_exactly(email_notification)
      end
    end
  end
end
