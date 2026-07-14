# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Onboarding', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before { sign_in user }

  describe 'GET /api/v1/onboarding/resume' do
    it 'returns goal_discovery when no primary goal exists' do
      get api_v1_onboarding_resume_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'current_step' => 'goal_discovery',
        'smart_goal_id' => nil,
        'habit_ids' => nil,
        'completion_id' => nil,
        'schedule_id' => nil
      )
    end

    it 'advances to habits when a primary uncompleted goal exists' do
      goal = create(:smart_goal, profile: profile, primary: true, completed: false)

      get api_v1_onboarding_resume_path

      body = response.parsed_body
      expect(body['current_step']).to eq('habits')
      expect(body['smart_goal_id']).to eq(goal.id)
    end

    it 'advances to todays_action when habits exist' do
      goal = create(:smart_goal, profile: profile, primary: true, completed: false)
      3.times { |i| create(:habit, profile: profile, smart_goal: goal, position: i + 1) }

      get api_v1_onboarding_resume_path

      body = response.parsed_body
      expect(body['current_step']).to eq('todays_action')
      expect(body['habit_ids'].size).to eq(3)
    end

    it 'advances to reminder when today\'s completion exists' do
      goal = create(:smart_goal, profile: profile, primary: true, completed: false)
      habit = create(:habit, profile: profile, smart_goal: goal, position: 1)
      completion = create(:habit_completion, habit: habit, completed_on: Date.current)

      get api_v1_onboarding_resume_path

      body = response.parsed_body
      expect(body['current_step']).to eq('reminder')
      expect(body['completion_id']).to eq(completion.id)
    end

    it 'advances to profile when a schedule is active' do
      goal = create(:smart_goal, profile: profile, primary: true, completed: false)
      habit = create(:habit, profile: profile, smart_goal: goal, position: 1)
      create(:habit_completion, habit: habit, completed_on: Date.current)
      schedule = create(:notification_schedule, profile: profile, active: true)

      get api_v1_onboarding_resume_path

      body = response.parsed_body
      expect(body['current_step']).to eq('profile')
      expect(body['schedule_id']).to eq(schedule.id)
    end

    it 'returns complete when onboarding_completed_at is set' do
      profile.update!(onboarding_completed_at: Time.current)

      get api_v1_onboarding_resume_path

      expect(response.parsed_body['current_step']).to eq('complete')
    end
  end
end
