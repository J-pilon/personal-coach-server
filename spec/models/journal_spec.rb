# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Journal, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to have_many(:journal_entries).dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:journal) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_uniqueness_of(:profile_id).scoped_to(:kind) }
  end

  describe 'kind enum' do
    it 'exposes default as a kind' do
      journal = create(:journal)
      expect(journal).to be_default
    end

    it 'rejects unknown kinds' do
      expect { build(:journal, kind: 'mystery') }.to raise_error(ArgumentError)
    end
  end

  describe 'one default journal per profile' do
    it 'prevents a profile from owning two default journals' do
      profile = create(:profile)
      create(:journal, profile: profile)

      duplicate = build(:journal, profile: profile)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:profile_id]).to be_present
    end

    it 'destroys child entries when the journal is deleted' do
      journal = create(:journal)
      create(:journal_entry, journal: journal, profile: journal.profile)

      expect { journal.destroy }.to change(JournalEntry, :count).by(-1)
    end
  end
end
