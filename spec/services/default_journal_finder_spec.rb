# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DefaultJournalFinder do
  describe '.call' do
    let(:profile) { create(:profile) }

    context 'when the profile has no journals yet' do
      it 'creates a default journal seeded with the standard title and description' do
        expect { described_class.call(profile) }.to change(Journal, :count).by(1)

        journal = profile.journals.first
        expect(journal.kind).to eq('default')
        expect(journal.title).to eq(DefaultJournalFinder::DEFAULT_TITLE)
        expect(journal.description).to eq(DefaultJournalFinder::DEFAULT_DESCRIPTION)
      end
    end

    context 'when the profile already has a default journal' do
      it 'returns the existing journal without creating a new one' do
        existing = described_class.call(profile)

        expect { described_class.call(profile) }.not_to change(Journal, :count)
        expect(described_class.call(profile)).to eq(existing)
      end
    end

    it 'scopes per profile (each profile gets its own default)' do
      other = create(:profile)

      mine = described_class.call(profile)
      theirs = described_class.call(other)

      expect(mine).not_to eq(theirs)
      expect(mine.profile).to eq(profile)
      expect(theirs.profile).to eq(other)
    end
  end
end
