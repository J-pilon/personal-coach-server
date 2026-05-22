# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JournalEntries::Create do
  describe '.call' do
    let(:profile) { create(:profile) }

    let(:valid_params) do
      {
        title: 'Today',
        body: 'Made progress on the journaling feature.',
        entry_type: 'daily_journal',
        occurred_on: Date.new(2026, 5, 21)
      }
    end

    context 'when the profile has no default journal yet' do
      it 'creates the default journal and the entry' do
        expect { described_class.call(profile: profile, params: valid_params) }
          .to change(Journal, :count).by(1)
          .and change(JournalEntry, :count).by(1)
      end

      it 'attaches the entry to the freshly created default journal' do
        entry = described_class.call(profile: profile, params: valid_params)
        expect(entry.journal).to eq(profile.journals.first)
        expect(entry.profile).to eq(profile)
      end
    end

    context 'when the profile already has a default journal' do
      let!(:existing) { create(:journal, profile: profile) }

      it 'reuses the existing journal' do
        expect { described_class.call(profile: profile, params: valid_params) }
          .to change(JournalEntry, :count).by(1)
          .and not_change(Journal, :count)

        expect(JournalEntry.last.journal).to eq(existing)
      end
    end

    it 'defaults occurred_on to today when not supplied' do
      params = valid_params.except(:occurred_on)
      entry = described_class.call(profile: profile, params: params)
      expect(entry.occurred_on).to eq(Date.current)
    end

    it 'defaults occurred_on to today when supplied as a blank string' do
      params = valid_params.merge(occurred_on: '')
      entry = described_class.call(profile: profile, params: params)
      expect(entry.occurred_on).to eq(Date.current)
    end

    it 'returns an unpersisted entry with errors when validation fails' do
      params = valid_params.merge(body: nil)
      entry = described_class.call(profile: profile, params: params)

      expect(entry).not_to be_persisted
      expect(entry.errors[:body]).to be_present
    end
  end
end
