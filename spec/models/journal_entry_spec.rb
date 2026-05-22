# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JournalEntry, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to belong_to(:journal) }
  end

  describe 'validations' do
    subject { build(:journal_entry) }

    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_presence_of(:entry_type) }
    it { is_expected.to validate_presence_of(:occurred_on) }
  end

  describe 'entry_type enum' do
    it 'accepts every documented entry type' do
      %w[daily_journal weekly_reflection general].each do |type|
        entry = build(:journal_entry, entry_type: type)
        expect(entry).to be_valid, "expected #{type} to be a valid entry_type"
      end
    end

    it 'rejects unknown entry types' do
      expect { build(:journal_entry, entry_type: 'rant') }.to raise_error(ArgumentError)
    end
  end
end
