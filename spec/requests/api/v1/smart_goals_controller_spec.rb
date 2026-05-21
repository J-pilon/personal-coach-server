# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::SmartGoals', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before do
    sign_in user
  end

  describe 'GET /api/v1/smart_goals' do
    context 'when user has smart goals' do
      let!(:smart_goals) { create_list(:smart_goal, 3, profile: profile) }

      it 'returns all smart goals for the user' do
        get api_v1_smart_goals_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response.length).to eq(3)
        expect(json_response.pluck('id')).to match_array(smart_goals.map(&:id))
      end

      it 'returns smart goal data with correct attributes' do
        get api_v1_smart_goals_path

        json_response = response.parsed_body
        goal = json_response.first

        expect(goal).to include(
          'id',
          'title',
          'description',
          'timeframe',
          'specific',
          'measurable',
          'achievable',
          'relevant',
          'time_bound',
          'completed',
          'target_date',
          'profile_id'
        )
      end
    end

    context 'when user has no smart goals' do
      it 'returns an empty array' do
        get api_v1_smart_goals_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to eq([])
      end
    end
  end

  describe 'GET /api/v1/smart_goals/:id' do
    let!(:smart_goal) { create(:smart_goal, profile: profile) }

    it 'returns the smart goal with all expected attributes' do
      get api_v1_smart_goal_path(smart_goal)

      expect(response).to have_http_status(:ok)
      json_response = response.parsed_body

      expect(json_response).to include(
        'id', 'title', 'description', 'timeframe',
        'specific', 'measurable', 'achievable', 'relevant', 'time_bound',
        'completed', 'target_date', 'profile_id', 'tasks'
      )
      expect(json_response['id']).to eq(smart_goal.id)
    end

    context 'with linked tasks' do
      let!(:open_task)      { create(:task, profile: profile, smart_goal: smart_goal, completed: false) }
      let!(:other_open)     { create(:task, profile: profile, smart_goal: smart_goal, completed: false) }
      let!(:completed_task) { create(:task, profile: profile, smart_goal: smart_goal, completed: true) }
      let!(:unlinked_task)  { create(:task, profile: profile, smart_goal: nil, completed: false) }

      it 'separates tasks into open and completed sections' do
        get api_v1_smart_goal_path(smart_goal)

        json_response = response.parsed_body
        open_ids = json_response['tasks']['open'].pluck('id')
        completed_ids = json_response['tasks']['completed'].pluck('id')

        expect(open_ids).to contain_exactly(open_task.id, other_open.id)
        expect(completed_ids).to eq([completed_task.id])
      end

      it 'excludes tasks belonging to other goals or no goal' do
        get api_v1_smart_goal_path(smart_goal)

        json_response = response.parsed_body
        all_ids = json_response['tasks']['open'].pluck('id') + json_response['tasks']['completed'].pluck('id')

        expect(all_ids).not_to include(unlinked_task.id)
      end

      it 'returns expected task attributes' do
        get api_v1_smart_goal_path(smart_goal)

        json_response = response.parsed_body
        task = json_response['tasks']['open'].first

        expect(task).to include(
          'id', 'title', 'description', 'completed',
          'action_category', 'priority', 'due_at', 'smart_goal_id'
        )
      end
    end

    context 'with no linked tasks' do
      it 'returns empty arrays for both sections' do
        get api_v1_smart_goal_path(smart_goal)

        json_response = response.parsed_body
        expect(json_response['tasks']['open']).to eq([])
        expect(json_response['tasks']['completed']).to eq([])
      end
    end

    context 'when more than 50 tasks per section exist' do
      before do
        create_list(:task, 51, profile: profile, smart_goal: smart_goal, completed: false)
        create_list(:task, 51, profile: profile, smart_goal: smart_goal, completed: true)
      end

      it 'caps each section at 50 entries' do
        get api_v1_smart_goal_path(smart_goal)

        json_response = response.parsed_body
        expect(json_response['tasks']['open'].size).to eq(50)
        expect(json_response['tasks']['completed'].size).to eq(50)
      end
    end

    context 'when smart goal does not exist' do
      it 'returns not found status' do
        get api_v1_smart_goal_path(999_999)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when smart goal belongs to a different user' do
      let!(:other_user) { create(:user) }
      let!(:other_smart_goal) { create(:smart_goal, profile: other_user.profile) }

      it 'returns not found status' do
        get api_v1_smart_goal_path(other_smart_goal)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/smart_goals' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          smart_goal: {
            title: 'Learn React Native',
            description: 'Master React Native development for mobile apps',
            timeframe: '3_months',
            specific: 'Complete 3 React Native projects',
            measurable: 'Build and deploy 3 working mobile applications',
            achievable: 'Dedicate 2 hours daily to learning and practice',
            relevant: 'Enhance mobile development skills for career growth',
            time_bound: 'Complete all projects within 3 months',
            completed: false,
            target_date: 3.months.from_now.to_date
          }
        }
      end

      it 'creates a new smart goal' do
        expect do
          post api_v1_smart_goals_path, params: valid_params
        end.to change(SmartGoal, :count).by(1)
      end

      it 'associates the smart goal with the current user profile' do
        post api_v1_smart_goals_path, params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body

        aggregate_failures 'diagnostics metadata' do
          expect(json_response['profile_id']).to eq(profile.id)
          expect(json_response['title']).to eq('Learn React Native')
          expect(json_response['description']).to eq('Master React Native development for mobile apps')
          expect(json_response['timeframe']).to eq('3_months')
          expect(json_response['specific']).to eq('Complete 3 React Native projects')
          expect(json_response['measurable']).to eq('Build and deploy 3 working mobile applications')
          expect(json_response['achievable']).to eq('Dedicate 2 hours daily to learning and practice')
          expect(json_response['relevant']).to eq('Enhance mobile development skills for career growth')
          expect(json_response['time_bound']).to eq('Complete all projects within 3 months')
          expect(json_response['completed']).to be(false)
        end
      end
    end

    context 'with invalid parameters' do
      context 'when title is missing' do
        let(:invalid_params) do
          {
            smart_goal: {
              description: 'Master React Native development for mobile apps',
              timeframe: '3_months',
              specific: 'Complete 3 React Native projects',
              measurable: 'Build and deploy 3 working mobile applications',
              achievable: 'Dedicate 2 hours daily to learning and practice',
              relevant: 'Enhance mobile development skills for career growth',
              time_bound: 'Complete all projects within 3 months',
              completed: false,
              target_date: 3.months.from_now.to_date
            }
          }
        end

        it 'does not create a smart goal' do
          expect do
            post api_v1_smart_goals_path, params: invalid_params
          end.not_to change(SmartGoal, :count)
        end

        it 'returns unprocessable entity status' do
          post api_v1_smart_goals_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_smart_goals_path, params: invalid_params

          json_response = response.parsed_body
          expect(json_response['errors']).to include("Title can't be blank")
        end
      end

      context 'when timeframe is invalid' do
        let(:invalid_params) do
          {
            smart_goal: {
              title: 'Learn React Native',
              description: 'Master React Native development for mobile apps',
              timeframe: 'invalid_timeframe',
              specific: 'Complete 3 React Native projects',
              measurable: 'Build and deploy 3 working mobile applications',
              achievable: 'Dedicate 2 hours daily to learning and practice',
              relevant: 'Enhance mobile development skills for career growth',
              time_bound: 'Complete all projects within 3 months',
              completed: false,
              target_date: 3.months.from_now.to_date
            }
          }
        end

        it 'returns unprocessable entity status' do
          post api_v1_smart_goals_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_smart_goals_path, params: invalid_params

          json_response = response.parsed_body
          expect(json_response['errors']).to include('Timeframe is not included in the list')
        end
      end

      context 'when specific is missing' do
        let(:invalid_params) do
          {
            smart_goal: {
              title: 'Learn React Native',
              description: 'Master React Native development for mobile apps',
              timeframe: '3_months',
              measurable: 'Build and deploy 3 working mobile applications',
              achievable: 'Dedicate 2 hours daily to learning and practice',
              relevant: 'Enhance mobile development skills for career growth',
              time_bound: 'Complete all projects within 3 months',
              completed: false,
              target_date: 3.months.from_now.to_date
            }
          }
        end

        it 'returns unprocessable entity status' do
          post api_v1_smart_goals_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_smart_goals_path, params: invalid_params

          json_response = response.parsed_body
          expect(json_response['errors']).to include("Specific can't be blank")
        end
      end
    end
  end

  describe 'PATCH /api/v1/smart_goals/:id' do
    let!(:smart_goal) { create(:smart_goal, profile: profile) }

    context 'with valid parameters' do
      let(:valid_params) do
        {
          smart_goal: {
            title: 'Updated Goal Title',
            description: 'Updated description',
            completed: true
          }
        }
      end

      it 'updates the smart goal' do
        patch api_v1_smart_goal_path(smart_goal), params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['title']).to eq('Updated Goal Title')
        expect(json_response['description']).to eq('Updated description')
        expect(json_response['completed']).to be(true)
      end

      it 'persists the changes to the database' do
        patch api_v1_smart_goal_path(smart_goal), params: valid_params

        smart_goal.reload
        expect(smart_goal.title).to eq('Updated Goal Title')
        expect(smart_goal.description).to eq('Updated description')
        expect(smart_goal.completed).to be(true)
      end
    end

    context 'with partial parameters' do
      let(:partial_params) do
        {
          smart_goal: {
            title: 'Partially Updated Title'
          }
        }
      end

      it 'updates only the provided fields' do
        original_description = smart_goal.description

        patch api_v1_smart_goal_path(smart_goal), params: partial_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['title']).to eq('Partially Updated Title')
        expect(json_response['description']).to eq(original_description)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          smart_goal: {
            timeframe: 'invalid_timeframe'
          }
        }
      end

      it 'returns unprocessable entity status' do
        patch api_v1_smart_goal_path(smart_goal), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        patch api_v1_smart_goal_path(smart_goal), params: invalid_params

        json_response = response.parsed_body
        expect(json_response['errors']).to include('Timeframe is not included in the list')
      end

      it 'does not update the smart goal' do
        original_timeframe = smart_goal.timeframe

        patch api_v1_smart_goal_path(smart_goal), params: invalid_params

        smart_goal.reload
        expect(smart_goal.timeframe).to eq(original_timeframe)
      end
    end

    context 'when smart goal does not exist' do
      it 'returns not found status' do
        patch api_v1_smart_goal_path(999_999), params: { smart_goal: { title: 'Updated Title' } }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when smart goal belongs to different user' do
      let!(:other_user) { create(:user) }
      let!(:other_profile) { other_user.profile }
      let!(:other_smart_goal) { create(:smart_goal, profile: other_profile) }

      it 'returns not found status' do
        patch api_v1_smart_goal_path(other_smart_goal), params: { smart_goal: { title: 'Updated Title' } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/smart_goals/:id' do
    let!(:smart_goal) { create(:smart_goal, profile: profile) }

    context 'when smart goal exists' do
      it 'deletes the smart goal' do
        expect do
          delete api_v1_smart_goal_path(smart_goal)
        end.to change(SmartGoal, :count).by(-1)
      end

      it 'returns no content status' do
        delete api_v1_smart_goal_path(smart_goal)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when smart goal does not exist' do
      it 'returns not found status' do
        delete api_v1_smart_goal_path(999_999)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when smart goal belongs to different user' do
      let!(:other_user) { create(:user) }
      let!(:other_profile) { other_user.profile }
      let!(:other_smart_goal) { create(:smart_goal, profile: other_profile) }

      it 'returns not found status' do
        delete api_v1_smart_goal_path(other_smart_goal)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
