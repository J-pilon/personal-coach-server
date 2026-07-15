# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::HabitCompletions', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }
  let!(:habit) { create(:habit, profile: profile) }

  before { sign_in user }

  describe 'POST /api/v1/habit_completions' do
    it 'creates a committed completion for today by default' do
      expect { post api_v1_habit_completions_path, params: { habit_completion: { habit_id: habit.id } }, as: :json }
        .to change(HabitCompletion, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['state']).to eq('committed')
      expect(body['completed_on']).to eq(Date.current.iso8601)
    end

    it 'is idempotent on repeat (habit_id, completed_on)' do
      existing = create(:habit_completion, habit: habit, completed_on: Date.current)

      expect { post api_v1_habit_completions_path, params: { habit_completion: { habit_id: habit.id } }, as: :json }
        .not_to(change(HabitCompletion, :count))

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['id']).to eq(existing.id)
    end

    it 'returns not found for another user\'s habit' do
      other_habit = create(:habit, profile: create(:user).profile)

      post api_v1_habit_completions_path, params: { habit_completion: { habit_id: other_habit.id } }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
