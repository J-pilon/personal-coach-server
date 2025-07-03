require 'rails_helper'

RSpec.describe Api::V1::TasksController, type: :request do
  describe 'GET /api/v1/tasks' do
    context 'when tasks exist' do
      let!(:tasks) { create_list(:task, 3) }

      it 'returns all tasks' do
        get '/api/v1/tasks'

        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(3)
        expect(json_response.first['title']).to be_present
        expect(json_response.first['description']).to be_present
        expect(json_response.first['completed']).to be_in([true, false])
      end
    end

    context 'when no tasks exist' do
      it 'returns empty array' do
        get '/api/v1/tasks'

        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end
    end
  end

  describe 'GET /api/v1/tasks/:id' do
    let(:task) { create(:task) }

    context 'when task exists' do
      it 'returns the task' do
        get "/api/v1/tasks/#{task.id}"

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(task.id)
        expect(json_response['title']).to eq(task.title)
        expect(json_response['description']).to eq(task.description)
        expect(json_response['completed']).to eq(task.completed)
      end
    end

    context 'when task does not exist' do
      it 'returns not found error' do
        get '/api/v1/tasks/999'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/tasks' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          task: {
            title: 'Test Task',
            description: 'Test Description',
            completed: false,
            action_category: 'do'
          }
        }
      end

      it 'creates a new task' do
        expect {
          post '/api/v1/tasks', params: valid_params
        }.to change(Task, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_response['title']).to eq('Test Task')
        expect(json_response['description']).to eq('Test Description')
        expect(json_response['completed']).to eq(false)
      end

      it 'creates a completed task' do
        valid_params[:task][:completed] = true

        post '/api/v1/tasks', params: valid_params

        expect(response).to have_http_status(:created)
        expect(json_response['completed']).to eq(true)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          task: {
            title: '',
            description: 'Test Description',
            completed: false,
            action_category: 'do'
          }
        }
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/tasks', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('title')
      end
    end

    context 'with missing task parameter' do
      it 'returns bad request' do
        post '/api/v1/tasks', params: { title: 'Test' }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'PUT /api/v1/tasks/:id' do
    let(:task) { create(:task) }

    context 'with valid parameters' do
      let(:update_params) do
        {
          task: {
            title: 'Updated Task',
            description: 'Updated Description',
            completed: true,
            action_category: 'defer'
          }
        }
      end

      it 'updates the task' do
        put "/api/v1/tasks/#{task.id}", params: update_params

        expect(response).to have_http_status(:ok)
        expect(json_response['title']).to eq('Updated Task')
        expect(json_response['description']).to eq('Updated Description')
        expect(json_response['completed']).to eq(true)
      end

      it 'partially updates the task' do
        partial_params = { task: { title: 'New Title', action_category: 'delegate' } }

        put "/api/v1/tasks/#{task.id}", params: partial_params

        expect(response).to have_http_status(:ok)
        expect(json_response['title']).to eq('New Title')
        expect(json_response['description']).to eq(task.description)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          task: {
            title: '',
            description: 'Updated Description',
            action_category: 'do'
          }
        }
      end

      it 'returns unprocessable entity status' do
        put "/api/v1/tasks/#{task.id}", params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('title')
      end
    end

    context 'when task does not exist' do
      it 'returns not found error' do
        put '/api/v1/tasks/999', params: { task: { title: 'Test' } }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/tasks/:id' do
    let!(:task) { create(:task) }

    context 'when task exists' do
      it 'deletes the task' do
        expect {
          delete "/api/v1/tasks/#{task.id}"
        }.to change(Task, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when task does not exist' do
      it 'returns not found error' do
        delete '/api/v1/tasks/999'

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
