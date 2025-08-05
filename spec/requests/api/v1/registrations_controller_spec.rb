require 'rails_helper'

RSpec.describe 'Api::V1::Registrations', type: :request do
  describe 'POST /api/v1/signup' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates a new user' do
        expect do
          post '/api/v1/signup', params: valid_params
        end.to change(User, :count).by(1)
      end

      it 'creates a profile for the user' do
        expect do
          post '/api/v1/signup', params: valid_params
        end.to change(Profile, :count).by(1)
      end

      it 'returns success status' do
        post '/api/v1/signup', params: valid_params
        expect(response).to have_http_status(:ok)
      end

      it 'returns user and profile data in correct format' do
        post '/api/v1/signup', params: valid_params

        json_response = JSON.parse(response.body)

        expect(json_response['status']['code']).to eq(200)
        expect(json_response['status']['message']).to eq('Signed up successfully.')
        expect(json_response['data']['user']['email']).to eq('newuser@example.com')
        expect(json_response['data']['user']['id']).to be_present
        expect(json_response['data']['user']['created_at']).to be_present
        expect(json_response['data']['user']['updated_at']).to be_present
        expect(json_response['data']['profile']['id']).to be_present
        expect(json_response['data']['profile']['user_id']).to be_present
        expect(json_response['data']['profile']['onboarding_status']).to eq('incomplete')
      end

      it 'returns JWT token in Authorization header' do
        post '/api/v1/signup', params: valid_params

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'does not return password in response' do
        post '/api/v1/signup', params: valid_params

        json_response = response.parsed_body
        expect(json_response['data']['user']['password']).to be_nil
        expect(json_response['data']['user']['password_digest']).to be_nil
      end

      it 'automatically signs in the user after registration' do
        post '/api/v1/signup', params: valid_params

        # The user should be able to access protected endpoints
        token = response.headers['Authorization']
        get '/api/v1/me', headers: { 'Authorization' => token }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with invalid parameters' do
      context 'when email is missing' do
        let(:invalid_params) do
          {
            user: {
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user' do
          expect do
            post '/api/v1/signup', params: invalid_params
          end.not_to change(User, :count)
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include("Email can't be blank")
        end
      end

      context 'when email is invalid' do
        let(:invalid_params) do
          {
            user: {
              email: 'invalid-email',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include('Email is invalid')
        end
      end

      context 'when email already exists' do
        let!(:existing_user) { create(:user, email: 'existing@example.com') }
        let(:duplicate_params) do
          {
            user: {
              email: 'existing@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user' do
          expect do
            post '/api/v1/signup', params: duplicate_params
          end.not_to change(User, :count)
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: duplicate_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: duplicate_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include('Email has already been taken')
        end
      end

      context 'when password is missing' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password_confirmation: 'password123'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include("Password can't be blank")
        end
      end

      context 'when password is too short' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: '123',
              password_confirmation: '123'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include('Password is too short')
        end
      end

      context 'when passwords do not match' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'differentpassword'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include("Password confirmation doesn't match Password")
        end
      end

      context 'when password confirmation is missing' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123'
            }
          }
        end

        it 'returns unprocessable entity status' do
          post '/api/v1/signup', params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error message' do
          post '/api/v1/signup', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['message']).to include("Password confirmation can't be blank")
        end
      end
    end

    context 'with malformed request' do
      it 'handles missing user parameter' do
        post '/api/v1/signup', params: {}
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'handles empty request body' do
        post '/api/v1/signup'
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
