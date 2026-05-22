# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Journals', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  describe 'GET /api/v1/journal' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api_v1_journal_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns the default journal with the expected fields' do
        get api_v1_journal_path

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).to include('id', 'title', 'description', 'kind', 'created_at', 'updated_at')
        expect(json['kind']).to eq('default')
        expect(json['title']).to eq(DefaultJournalFinder::DEFAULT_TITLE)
        expect(json['description']).to eq(DefaultJournalFinder::DEFAULT_DESCRIPTION)
      end

      it 'lazily creates the default journal on first request' do
        expect(profile.journals).to be_empty
        expect { get api_v1_journal_path }.to change { profile.journals.reload.count }.by(1)
      end

      it 'returns the existing default journal without creating a duplicate' do
        existing = create(:journal, profile: profile)

        expect { get api_v1_journal_path }.not_to(change { profile.journals.reload.count })
        expect(response.parsed_body['id']).to eq(existing.id)
      end
    end
  end
end
