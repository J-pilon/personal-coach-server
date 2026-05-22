# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::JournalEntries', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }
  let!(:journal) { create(:journal, profile: profile) }

  describe 'GET /api/v1/journal/journal_entries' do
    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api_v1_journal_journal_entries_path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns only entries belonging to the current profile' do
        mine = create(:journal_entry, profile: profile, journal: journal)
        other_profile = create(:profile)
        create(:journal_entry, profile: other_profile, journal: create(:journal, profile: other_profile))

        get api_v1_journal_journal_entries_path

        ids = response.parsed_body.pluck('id')
        expect(ids).to eq([mine.id])
      end

      it 'orders entries by occurred_on desc, then created_at desc' do
        older = create(:journal_entry, profile: profile, journal: journal, occurred_on: 3.days.ago.to_date)
        newer = create(:journal_entry, profile: profile, journal: journal, occurred_on: Date.current)

        get api_v1_journal_journal_entries_path

        expect(response.parsed_body.pluck('id')).to eq([newer.id, older.id])
      end

      it 'returns an empty array when the profile has no entries' do
        get api_v1_journal_journal_entries_path
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end

      context 'with filters' do
        let!(:daily) do
          create(:journal_entry, profile: profile, journal: journal, occurred_on: Date.new(2026, 5, 10))
        end
        let!(:weekly) do
          create(:journal_entry, :weekly, profile: profile, journal: journal, occurred_on: Date.new(2026, 5, 17))
        end
        let!(:general) do
          create(:journal_entry, :general, profile: profile, journal: journal, occurred_on: Date.new(2026, 4, 1))
        end

        it 'filters by entry_type' do
          get api_v1_journal_journal_entries_path, params: { entry_type: 'weekly_reflection' }
          expect(response.parsed_body.pluck('id')).to eq([weekly.id])
        end

        it 'filters by exact occurred_on' do
          get api_v1_journal_journal_entries_path, params: { occurred_on: '2026-05-10' }
          expect(response.parsed_body.pluck('id')).to eq([daily.id])
        end

        it 'filters by start_date (inclusive)' do
          get api_v1_journal_journal_entries_path, params: { start_date: '2026-05-01' }
          expect(response.parsed_body.pluck('id')).to contain_exactly(daily.id, weekly.id)
        end

        it 'filters by end_date (inclusive)' do
          get api_v1_journal_journal_entries_path, params: { end_date: '2026-05-10' }
          expect(response.parsed_body.pluck('id')).to contain_exactly(daily.id, general.id)
        end

        it 'combines start_date, end_date, and entry_type' do
          get api_v1_journal_journal_entries_path,
              params: { start_date: '2026-05-01', end_date: '2026-05-15', entry_type: 'daily_journal' }
          expect(response.parsed_body.pluck('id')).to eq([daily.id])
        end
      end
    end
  end

  describe 'GET /api/v1/journal/journal_entries/:id' do
    let!(:entry) { create(:journal_entry, profile: profile, journal: journal) }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api_v1_journal_journal_entry_path(entry)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'returns the entry with the expected fields' do
        get api_v1_journal_journal_entry_path(entry)

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json).to include(
          'id', 'journal_id', 'profile_id', 'title', 'body',
          'entry_type', 'occurred_on', 'created_at', 'updated_at'
        )
        expect(json['id']).to eq(entry.id)
      end

      it 'returns 404 for an entry belonging to another profile' do
        other_profile = create(:profile)
        other_entry = create(:journal_entry, profile: other_profile, journal: create(:journal, profile: other_profile))

        get api_v1_journal_journal_entry_path(other_entry)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for an entry that does not exist' do
        get api_v1_journal_journal_entry_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/journal/journal_entries' do
    let(:valid_params) do
      {
        journal_entry: {
          title: 'Today',
          body: 'Made progress on the journaling feature.',
          entry_type: 'daily_journal',
          occurred_on: '2026-05-21'
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        post api_v1_journal_journal_entries_path, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'creates the entry under the profile and journal' do
        expect { post api_v1_journal_journal_entries_path, params: valid_params }
          .to change(JournalEntry, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['profile_id']).to eq(profile.id)
        expect(json['journal_id']).to eq(journal.id)
        expect(json['title']).to eq('Today')
        expect(json['body']).to eq('Made progress on the journaling feature.')
        expect(json['entry_type']).to eq('daily_journal')
        expect(json['occurred_on']).to eq('2026-05-21')
      end

      it 'lazily creates the default journal if the profile has none' do
        profile.journals.destroy_all

        expect { post api_v1_journal_journal_entries_path, params: valid_params }
          .to change { profile.journals.reload.count }.by(1)
          .and change(JournalEntry, :count).by(1)

        new_journal = profile.journals.first
        expect(response.parsed_body['journal_id']).to eq(new_journal.id)
      end

      it 'defaults occurred_on to today when omitted' do
        params = valid_params.deep_dup
        params[:journal_entry].delete(:occurred_on)

        post api_v1_journal_journal_entries_path, params: params

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['occurred_on']).to eq(Date.current.to_s)
      end

      it 'ignores client-supplied profile_id and journal_id' do
        other_profile = create(:profile)
        other_journal = create(:journal, profile: other_profile)
        params = valid_params.deep_dup
        params[:journal_entry][:profile_id] = other_profile.id
        params[:journal_entry][:journal_id] = other_journal.id

        post api_v1_journal_journal_entries_path, params: params

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json['profile_id']).to eq(profile.id)
        expect(json['journal_id']).to eq(journal.id)
      end

      it 'returns 422 with errors when body is missing' do
        params = { journal_entry: { entry_type: 'daily_journal' } }

        expect { post api_v1_journal_journal_entries_path, params: params }
          .not_to change(JournalEntry, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include("Body can't be blank")
      end

      it 'returns 422 for an unknown entry_type' do
        params = { journal_entry: { body: 'x', entry_type: 'rant' } }

        post api_v1_journal_journal_entries_path, params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('Entry type is not included in the list')
      end
    end
  end

  describe 'PATCH /api/v1/journal/journal_entries/:id' do
    let!(:entry) { create(:journal_entry, profile: profile, journal: journal, body: 'old') }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch api_v1_journal_journal_entry_path(entry), params: { journal_entry: { body: 'new' } }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'updates the entry' do
        patch api_v1_journal_journal_entry_path(entry), params: { journal_entry: { body: 'new body' } }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['body']).to eq('new body')
        expect(entry.reload.body).to eq('new body')
      end

      it 'returns 422 with errors when body is set to blank' do
        patch api_v1_journal_journal_entry_path(entry), params: { journal_entry: { body: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include("Body can't be blank")
      end

      it 'returns 422 for an unknown entry_type' do
        patch api_v1_journal_journal_entry_path(entry), params: { journal_entry: { entry_type: 'rant' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('Entry type is not included in the list')
      end

      it 'returns 404 for an entry belonging to another profile' do
        other_profile = create(:profile)
        other_entry = create(:journal_entry, profile: other_profile, journal: create(:journal, profile: other_profile))

        patch api_v1_journal_journal_entry_path(other_entry), params: { journal_entry: { body: 'hack' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/journal/journal_entries/:id' do
    let!(:entry) { create(:journal_entry, profile: profile, journal: journal) }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        delete api_v1_journal_journal_entry_path(entry)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'deletes the entry and returns no content' do
        expect { delete api_v1_journal_journal_entry_path(entry) }
          .to change(JournalEntry, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for an entry belonging to another profile' do
        other_profile = create(:profile)
        other_entry = create(:journal_entry, profile: other_profile, journal: create(:journal, profile: other_profile))

        expect { delete api_v1_journal_journal_entry_path(other_entry) }
          .not_to change(JournalEntry, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
