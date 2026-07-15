# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Habits', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }
  let!(:smart_goal) { create(:smart_goal, profile: profile) }

  before { sign_in user }

  def habit_attrs(position:, title: 'Read for 10 min')
    {
      title: title,
      frequency: 'daily',
      frequency_config: {},
      cue: 'after coffee',
      minimum_version: '1 minute',
      normal_version: '10 minutes',
      position: position
    }
  end

  describe 'POST /api/v1/habits' do
    it 'creates 3 habits linked to the goal' do
      params = {
        smart_goal_id: smart_goal.id,
        habits: [1, 2, 3].map { |p| habit_attrs(position: p, title: "H#{p}") }
      }

      expect { post api_v1_habits_path, params: params, as: :json }
        .to change(Habit, :count).by(3)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.length).to eq(3)
      expect(smart_goal.habits.active.count).to eq(3)
    end

    it 'rejects a 4th habit' do
      params = {
        smart_goal_id: smart_goal.id,
        habits: (1..4).map { |p| habit_attrs(position: ((p - 1) % 3) + 1, title: "H#{p}") }
      }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(Habit.count).to eq(0)
    end

    it 'rejects when goal already has 3 active habits' do
      3.times { |i| create(:habit, profile: profile, smart_goal: smart_goal, position: i + 1) }

      params = { smart_goal_id: smart_goal.id, habits: [habit_attrs(position: 1, title: 'New')] }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns not found for another user\'s goal' do
      other_goal = create(:smart_goal, profile: create(:user).profile)
      params = { smart_goal_id: other_goal.id, habits: [habit_attrs(position: 1)] }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns validation errors on invalid habit' do
      params = {
        smart_goal_id: smart_goal.id,
        habits: [habit_attrs(position: 1).merge(title: '')]
      }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body['errors']).to be_present
    end
  end

  describe 'GET /api/v1/habits' do
    let!(:habit1) { create(:habit, profile: profile, smart_goal: smart_goal, position: 1) }
    let!(:habit2) { create(:habit, profile: profile, smart_goal: smart_goal, position: 2) }

    it 'returns the profile\'s active habits ordered by position' do
      archived = create(:habit, profile: profile, smart_goal: smart_goal, position: 3)
      archived.update!(archived_at: Time.current)

      get api_v1_habits_path

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.pluck('id')
      expect(ids).to eq([habit1.id, habit2.id])
    end

    it 'scopes results to smart_goal_id when provided' do
      other_goal = create(:smart_goal, profile: profile)
      create(:habit, profile: profile, smart_goal: other_goal, position: 1)

      get api_v1_habits_path, params: { smart_goal_id: smart_goal.id }

      expect(response.parsed_body.pluck('smart_goal_id').uniq).to eq([smart_goal.id])
    end

    it 'does not return another profile\'s habits' do
      other_profile = create(:user).profile
      other_goal = create(:smart_goal, profile: other_profile)
      create(:habit, profile: other_profile, smart_goal: other_goal, position: 1)

      get api_v1_habits_path

      expect(response.parsed_body.pluck('id')).to contain_exactly(habit1.id, habit2.id)
    end
  end
end
