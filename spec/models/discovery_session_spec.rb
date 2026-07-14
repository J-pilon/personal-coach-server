# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiscoverySession, type: :model do
  it 'is valid with default factory' do
    expect(build(:discovery_session)).to be_valid
  end

  describe 'validations' do
    it 'rejects turn_count above cap' do
      session = build(:discovery_session, turn_count: DiscoverySession::MAX_TURNS + 1)
      expect(session).not_to be_valid
      expect(session.errors[:turn_count]).to be_present
    end

    it 'rejects negative turn_count' do
      session = build(:discovery_session, turn_count: -1)
      expect(session).not_to be_valid
    end

    it 'exposes only the three declared statuses' do
      expect(described_class.statuses.keys).to contain_exactly('active', 'drafted', 'abandoned')
    end
  end

  describe '#append_message!' do
    it 'appends a message and persists it' do
      session = create(:discovery_session)

      session.append_message!(role: :assistant, text: 'What matters to you?')

      expect(session.reload.messages).to eq(
        [{ 'role' => 'assistant', 'text' => 'What matters to you?', 'turn' => 1 }]
      )
    end
  end

  describe '#turn_cap_reached?' do
    it 'is true one turn before the cap' do
      expect(build(:discovery_session, turn_count: DiscoverySession::MAX_TURNS - 1)).to be_turn_cap_reached
    end

    it 'is false earlier' do
      expect(build(:discovery_session, turn_count: 0)).not_to be_turn_cap_reached
    end
  end
end
