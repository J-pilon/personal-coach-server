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
      json = response.parsed_body
      expect(json['error']).to be_present
      expect(json['error']['code']).to eq('')
      expect(json['error']['message']).to eq('At most 3 habits allowed')
      expect(json['error']['details']).to be_nil
    end

    it 'rejects when goal already has 3 active habits' do
      3.times { |i| create(:habit, profile: profile, smart_goal: smart_goal, position: i + 1) }

      params = { smart_goal_id: smart_goal.id, habits: [habit_attrs(position: 1, title: 'New')] }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']).to be_present
      expect(json['error']['code']).to eq('')
      expect(json['error']['message']).to eq('Goal already has the maximum number of habits')
      expect(json['error']['details']).to be_nil
    end

    it 'returns not found for another user\'s goal' do
      other_goal = create(:smart_goal, profile: create(:user).profile)
      params = { smart_goal_id: other_goal.id, habits: [habit_attrs(position: 1)] }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:not_found)
      json = response.parsed_body
      expect(json['error']).to be_present
      expect(json['error']['code']).to eq('')
      expect(json['error']['message']).to eq('SmartGoal not found')
      expect(json['error']['details']).to be_nil
    end

    it 'returns validation errors on invalid habit' do
      params = {
        smart_goal_id: smart_goal.id,
        habits: [habit_attrs(position: 1).merge(title: '')]
      }

      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']).to be_present
      expect(json['error']['code']).to eq('')
      expect(json['error']['message']).to include("Title can't be blank")
      expect(json['error']['details']).to be_present
      expect(json['error']['details']['title']).to include("can't be blank")
    end

    context 'when position is omitted' do
      def attrs_without_position(title: 'Read for 10 min')
        habit_attrs(position: 1, title: title).except(:position)
      end

      it 'assigns position 1 to the first habit' do
        params = { smart_goal_id: smart_goal.id, habits: [attrs_without_position] }

        post api_v1_habits_path, params: params, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body.first['position']).to eq(1)
      end

      it 'assigns the lowest free position among active habits' do
        create(:habit, profile: profile, smart_goal: smart_goal, position: 1)
        create(:habit, profile: profile, smart_goal: smart_goal, position: 3)

        params = { smart_goal_id: smart_goal.id, habits: [attrs_without_position] }

        post api_v1_habits_path, params: params, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body.first['position']).to eq(2)
      end

      it 'reuses the position of an archived habit' do
        create(:habit, :archived, profile: profile, smart_goal: smart_goal, position: 1)
        create(:habit, profile: profile, smart_goal: smart_goal, position: 2)

        params = { smart_goal_id: smart_goal.id, habits: [attrs_without_position] }

        post api_v1_habits_path, params: params, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body.first['position']).to eq(1)
      end

      it 'assigns distinct positions to several habits created together' do
        params = {
          smart_goal_id: smart_goal.id,
          habits: [attrs_without_position(title: 'A'), attrs_without_position(title: 'B')]
        }

        post api_v1_habits_path, params: params, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body.pluck('position')).to eq([1, 2])
      end

      it 'rejects a 4th active habit' do
        3.times { |i| create(:habit, profile: profile, smart_goal: smart_goal, position: i + 1) }

        params = { smart_goal_id: smart_goal.id, habits: [attrs_without_position] }

        expect { post api_v1_habits_path, params: params, as: :json }.not_to change(Habit, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']['message']).to eq('Goal already has the maximum number of habits')
      end
    end

    context 'when position is already taken by an active habit' do
      it 'returns a standard 422 error instead of failing' do
        create(:habit, profile: profile, smart_goal: smart_goal, position: 1)

        params = { smart_goal_id: smart_goal.id, habits: [habit_attrs(position: 1)] }

        expect { post api_v1_habits_path, params: params, as: :json }.not_to change(Habit, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']['message']).to eq('Habit position is already taken')
      end
    end

    context 'when frequency is validated' do
      %w[daily weekdays].each do |frequency|
        it "accepts #{frequency}" do
          params = {
            smart_goal_id: smart_goal.id,
            habits: [habit_attrs(position: 1).merge(frequency: frequency)]
          }

          post api_v1_habits_path, params: params, as: :json

          expect(response).to have_http_status(:created)
          expect(response.parsed_body.first['frequency']).to eq(frequency)
        end
      end

      %w[weekly_n_times custom bogus].each do |frequency|
        it "rejects #{frequency}" do
          params = {
            smart_goal_id: smart_goal.id,
            habits: [habit_attrs(position: 1).merge(frequency: frequency)]
          }

          expect { post api_v1_habits_path, params: params, as: :json }.not_to change(Habit, :count)

          expect(response).to have_http_status(:unprocessable_content)
          json = response.parsed_body
          expect(json['error']['message']).to eq('Frequency must be daily or weekdays')
          expect(json['error']['details']['frequency']).to be_present
        end
      end

      it 'rejects a missing frequency' do
        params = {
          smart_goal_id: smart_goal.id,
          habits: [habit_attrs(position: 1).except(:frequency)]
        }

        expect { post api_v1_habits_path, params: params, as: :json }.not_to change(Habit, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'PATCH /api/v1/habits/:id' do
    let!(:habit) do
      create(:habit, profile: profile, smart_goal: smart_goal, position: 2, frequency: 'daily')
    end

    let(:update_params) do
      {
        title: 'Walk after lunch',
        cue: 'after lunch',
        minimum_version: 'put on shoes',
        normal_version: 'walk 15 minutes',
        frequency: 'weekdays'
      }
    end

    it 'updates the editable fields' do
      patch api_v1_habit_path(habit), params: update_params, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'id' => habit.id,
        'title' => 'Walk after lunch',
        'cue' => 'after lunch',
        'minimum_version' => 'put on shoes',
        'normal_version' => 'walk 15 minutes',
        'frequency' => 'weekdays'
      )
      expect(habit.reload.title).to eq('Walk after lunch')
    end

    it 'does not change smart_goal_id or position' do
      other_goal = create(:smart_goal, profile: profile)

      patch api_v1_habit_path(habit),
            params: update_params.merge(smart_goal_id: other_goal.id, position: 3),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(habit.reload.smart_goal_id).to eq(smart_goal.id)
      expect(habit.position).to eq(2)
    end

    it 'allows a partial update' do
      patch api_v1_habit_path(habit), params: { cue: 'after breakfast' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(habit.reload.cue).to eq('after breakfast')
    end

    it 'returns validation errors for a blank title' do
      patch api_v1_habit_path(habit), params: { title: '' }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']['message']).to include("Title can't be blank")
      expect(json['error']['details']['title']).to include("can't be blank")
    end

    %w[weekly_n_times custom bogus].each do |frequency|
      it "rejects #{frequency} frequency" do
        patch api_v1_habit_path(habit), params: { frequency: frequency }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = response.parsed_body
        expect(json['error']['message']).to eq('Frequency must be daily or weekdays')
        expect(json['error']['details']['frequency']).to be_present
        expect(habit.reload.frequency).to eq('daily')
      end
    end

    it 'returns not found for another profile\'s habit' do
      other_profile = create(:user).profile
      foreign_habit = create(:habit, profile: other_profile, position: 1)

      patch api_v1_habit_path(foreign_habit), params: update_params, as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']['message']).to eq('Habit not found')
      expect(foreign_habit.reload.title).not_to eq('Walk after lunch')
    end

    it 'returns not found for an archived habit' do
      habit.update!(archived_at: Time.current)

      patch api_v1_habit_path(habit), params: update_params, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for an unknown id' do
      patch api_v1_habit_path(id: 0), params: update_params, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/habits/:id' do
    let!(:habit) { create(:habit, profile: profile, smart_goal: smart_goal, position: 1) }

    it 'soft deletes the habit and returns 204' do
      expect { delete api_v1_habit_path(habit) }.not_to change(Habit, :count)

      expect(response).to have_http_status(:no_content)
      expect(habit.reload.archived_at).to be_present
    end

    it 'keeps completion history' do
      create(:habit_completion, habit: habit)

      expect { delete api_v1_habit_path(habit) }.not_to change(HabitCompletion, :count)
    end

    it 'removes the habit from the active list' do
      delete api_v1_habit_path(habit)

      sign_in user
      get api_v1_habits_path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck('id')).not_to include(habit.id)
    end

    it 'frees the position slot for a new habit' do
      delete api_v1_habit_path(habit)

      sign_in user
      params = {
        smart_goal_id: smart_goal.id,
        habits: [habit_attrs(position: 1).except(:position)]
      }
      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.first['position']).to eq(1)
    end

    it 'lets a goal at the 3-habit cap add a habit after one is deleted' do
      create(:habit, profile: profile, smart_goal: smart_goal, position: 2)
      create(:habit, profile: profile, smart_goal: smart_goal, position: 3)
      delete api_v1_habit_path(habit)

      sign_in user
      params = { smart_goal_id: smart_goal.id, habits: [habit_attrs(position: 1)] }
      post api_v1_habits_path, params: params, as: :json

      expect(response).to have_http_status(:created)
    end

    it 'returns not found for another profile\'s habit' do
      other_profile = create(:user).profile
      foreign_habit = create(:habit, profile: other_profile, position: 1)

      delete api_v1_habit_path(foreign_habit)

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']['message']).to eq('Habit not found')
      expect(foreign_habit.reload.archived_at).to be_nil
    end

    it 'returns not found when the habit is already archived' do
      habit.update!(archived_at: Time.current)

      delete api_v1_habit_path(habit)

      expect(response).to have_http_status(:not_found)
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
