# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Tasks', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before do
    sign_in user
  end

  describe 'GET /api/v1/tasks' do
    context 'when user has tasks' do
      let!(:tasks) { create_list(:task, 3, profile: profile) }

      it 'returns all tasks for the user' do
        get api_v1_tasks_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response.length).to eq(3)
        expect(json_response.pluck('id')).to match_array(tasks.map(&:id))
      end

      it 'returns task data with correct attributes' do
        get api_v1_tasks_path

        json_response = response.parsed_body
        task = json_response.first

        expect(task).to include(
          'id',
          'title',
          'description',
          'completed',
          'action_category',
          'profile_id'
        )
      end
    end

    context 'when user has no tasks' do
      it 'returns an empty array' do
        get api_v1_tasks_path

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response).to eq([])
      end
    end
  end

  describe 'GET /api/v1/tasks/:id' do
    let!(:task) { create(:task, profile: profile) }

    context 'when task exists' do
      it 'returns the task data' do
        get api_v1_task_path(task)

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['id']).to eq(task.id)
        expect(json_response['title']).to eq(task.title)
        expect(json_response['description']).to eq(task.description)
        expect(json_response['completed']).to eq(task.completed)
        expect(json_response['action_category']).to eq(task.action_category)
      end
    end

    context 'when task does not exist' do
      it 'returns not found status' do
        get api_v1_task_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when task belongs to different user' do
      let!(:other_user) { create(:user) }
      let!(:other_task) { create(:task, profile: other_user.profile) }

      it 'returns not found status' do
        get api_v1_task_path(other_task)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/tasks' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          task: {
            title: 'Complete project documentation',
            description: 'Write comprehensive documentation for the new feature',
            completed: false,
            action_category: 'do'
          }
        }
      end

      it 'creates a new task' do
        expect do
          post api_v1_tasks_path, params: valid_params
        end.to change(Task, :count).by(1)
      end

      it 'associates the task with the current user profile' do
        post api_v1_tasks_path, params: valid_params

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body

        expect(json_response['profile_id']).to eq(profile.id)
        expect(json_response['title']).to eq('Complete project documentation')
        expect(json_response['description']).to eq('Write comprehensive documentation for the new feature')
        expect(json_response['completed']).to be(false)
        expect(json_response['action_category']).to eq('do')
      end
    end

    context 'with invalid parameters' do
      context 'when title is missing' do
        let(:invalid_params) do
          {
            task: {
              description: 'Write comprehensive documentation for the new feature',
              completed: false,
              action_category: 'do'
            }
          }
        end

        it 'does not create a task' do
          expect do
            post api_v1_tasks_path, params: invalid_params
          end.not_to change(Task, :count)
        end

        it 'returns unprocessable entity status' do
          post api_v1_tasks_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_tasks_path, params: invalid_params

          json_response = response.parsed_body
          expect(json_response['errors']).to include("Title can't be blank")
        end
      end

      context 'when action_category is invalid' do
        let(:invalid_params) do
          {
            task: {
              title: 'Complete project documentation',
              description: 'Write comprehensive documentation for the new feature',
              completed: false,
              action_category: 'invalid_category'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post api_v1_tasks_path, params: invalid_params

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH /api/v1/tasks/:id' do
    let!(:task) { create(:task, profile: profile) }

    context 'with valid parameters' do
      let(:valid_params) do
        {
          task: {
            title: 'Updated task title',
            description: 'Updated task description',
            completed: true,
            action_category: 'delegate'
          }
        }
      end

      it 'updates the task' do
        patch api_v1_task_path(task), params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['title']).to eq('Updated task title')
        expect(json_response['description']).to eq('Updated task description')
        expect(json_response['completed']).to be(true)
        expect(json_response['action_category']).to eq('delegate')
      end

      it 'persists the changes to the database' do
        patch api_v1_task_path(task), params: valid_params

        task.reload
        expect(task.title).to eq('Updated task title')
        expect(task.description).to eq('Updated task description')
        expect(task.completed).to be(true)
        expect(task.action_category).to eq('delegate')
      end
    end

    context 'with partial parameters' do
      let(:partial_params) do
        {
          task: {
            completed: true
          }
        }
      end

      it 'updates only the provided fields' do
        original_title = task.title

        patch api_v1_task_path(task), params: partial_params

        expect(response).to have_http_status(:ok)
        json_response = response.parsed_body

        expect(json_response['completed']).to be(true)
        expect(json_response['title']).to eq(original_title)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          task: {
            action_category: 'invalid_category'
          }
        }
      end

      it 'returns unprocessable entity status' do
        patch api_v1_task_path(task), params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        patch api_v1_task_path(task), params: invalid_params

        json_response = response.parsed_body
        expect(json_response['errors']).to include('Action category is not included in the list')
      end

      it 'does not update the task' do
        original_action_category = task.action_category

        patch api_v1_task_path(task), params: invalid_params

        task.reload
        expect(task.action_category).to eq(original_action_category)
      end
    end

    context 'when task does not exist' do
      it 'returns not found status' do
        patch api_v1_task_path(999_999), params: { task: { title: 'Updated Title' } }

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when task belongs to different user' do
      let!(:other_user) { create(:user) }
      let!(:other_task) { create(:task, profile: other_user.profile) }

      it 'returns not found status' do
        patch api_v1_task_path(other_task), params: { task: { title: 'Updated Title' } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/tasks/:id' do
    let!(:task) { create(:task, profile: profile) }

    context 'when task exists' do
      it 'deletes the task' do
        expect do
          delete api_v1_task_path(task)
        end.to change(Task, :count).by(-1)
      end

      it 'returns no content status' do
        delete api_v1_task_path(task)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when task does not exist' do
      it 'returns not found status' do
        delete api_v1_task_path(999_999)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when task belongs to different user' do
      let!(:other_user) { create(:user) }
      let!(:other_task) { create(:task, profile: other_user.profile) }

      it 'returns not found status' do
        delete api_v1_task_path(other_task)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
