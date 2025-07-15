require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'POST /api/v1/users' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post api_v1_users_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'creates a profile for the user' do
        expect {
          post api_v1_users_path, params: valid_params
        }.to change(Profile, :count).by(1)
      end

      it 'returns the user and profile data' do
        post api_v1_users_path, params: valid_params

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)

        expect(json_response['user']['email']).to eq('test@example.com')
        expect(json_response['profile']).to be_present
        expect(json_response['user']['password_digest']).to be_nil
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
          expect {
            post api_v1_users_path, params: invalid_params
          }.not_to change(User, :count)
        end

        it 'returns unprocessable entity status' do
          post api_v1_users_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_users_path, params: invalid_params
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include("Email can't be blank")
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
          post api_v1_users_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_users_path, params: invalid_params
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include('Email is invalid')
        end
      end

      context 'when email already exists' do
        let!(:existing_user) { create(:user, email: 'test@example.com') }
        let(:duplicate_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        end

        it 'does not create a user' do
          expect {
            post api_v1_users_path, params: duplicate_params
          }.not_to change(User, :count)
        end

        it 'returns unprocessable entity status' do
          post api_v1_users_path, params: duplicate_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_users_path, params: duplicate_params
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include('Email has already been taken')
        end
      end

      context 'when password confirmation does not match' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'password123',
              password_confirmation: 'different_password'
            }
          }
        end

        it 'does not create a user' do
          expect {
            post api_v1_users_path, params: invalid_params
          }.not_to change(User, :count)
        end

        it 'returns unprocessable entity status' do
          post api_v1_users_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns error messages' do
          post api_v1_users_path, params: invalid_params
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include("Password confirmation doesn't match Password")
        end
      end
    end
  end

  describe 'GET /api/v1/users/:id' do
    let!(:user) { create(:user) }

    context 'when user exists' do
      it 'returns the user and profile data' do
        get api_v1_user_path(user)

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['user']['email']).to eq(user.email)
        expect(json_response['profile']).to be_present
        expect(json_response['user']['password_digest']).to be_nil
      end
    end

    context 'when user does not exist' do
      it 'returns not found status' do
        get api_v1_user_path(999999)
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        get api_v1_user_path(999999)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to eq('User could not be found.')
      end
    end
  end
end
