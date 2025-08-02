require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  describe 'POST /api/v1/login' do
    let(:user) do
      user = User.create!(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      user
    end

    context 'with valid credentials' do
      let(:valid_params) do
        {
          user: {
            email: 'test@example.com',
            password: 'password123'
          }
        }
      end

      it 'returns success status' do
        # Debug: Check if user exists and can authenticate
        expect(user.valid_password?('password123')).to be true
        expect(user.email).to eq('test@example.com')
        expect(user.persisted?).to be true

        # Debug: Check the actual route being hit
        puts "User ID: #{user.id}"
        puts "User email: #{user.email}"
        puts "User password: #{user.password}"

        # Try to authenticate the user manually first
        user.valid_password?('password123')

        # Try a simple POST request first
        post '/api/v1/login', params: { user: { email: 'test@example.com', password: 'password123' } }

        # Debug: Check response body
        puts "Response status: #{response.status}"
        puts "Response body: #{response.body}"

        expect(response).to have_http_status(:ok)
      end

      it 'returns user data in correct format' do
        post '/api/v1/login', params: valid_params

        json_response = JSON.parse(response.body)

        expect(json_response['status']['code']).to eq(200)
        expect(json_response['status']['message']).to eq('Logged in successfully.')
        expect(json_response['status']['data']['id']).to eq(user.id)
        expect(json_response['status']['data']['email']).to eq('test@example.com')
        expect(json_response['status']['data']['created_at']).to be_present
        expect(json_response['status']['data']['updated_at']).to be_present
      end

      it 'returns JWT token in Authorization header' do
        post '/api/v1/login', params: valid_params

        expect(response.headers['Authorization']).to be_present
        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it 'does not return password in response' do
        post '/api/v1/login', params: valid_params

        json_response = JSON.parse(response.body)
        expect(json_response['status']['data']['password']).to be_nil
        expect(json_response['status']['data']['password_digest']).to be_nil
      end
    end

    context 'with invalid credentials' do
      context 'when email does not exist' do
        let(:invalid_params) do
          {
            user: {
              email: 'nonexistent@example.com',
              password: 'password123'
            }
          }
        end

        it 'returns unauthorized status' do
          post '/api/v1/login', params: invalid_params
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns error message' do
          post '/api/v1/login', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['code']).to eq(401)
          expect(json_response['status']['message']).to eq('Invalid email or password.')
        end
      end

      context 'when password is incorrect' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com',
              password: 'wrongpassword'
            }
          }
        end

        it 'returns unauthorized status' do
          post '/api/v1/login', params: invalid_params
          expect(response).to have_http_status(:unauthorized)
        end

        it 'returns error message' do
          post '/api/v1/login', params: invalid_params

          json_response = JSON.parse(response.body)
          expect(json_response['status']['code']).to eq(401)
          expect(json_response['status']['message']).to eq('Invalid email or password.')
        end
      end

      context 'when email is missing' do
        let(:invalid_params) do
          {
            user: {
              password: 'password123'
            }
          }
        end

        it 'returns unauthorized status' do
          post '/api/v1/login', params: invalid_params
          expect(response).to have_http_status(:unauthorized)
        end
      end

      context 'when password is missing' do
        let(:invalid_params) do
          {
            user: {
              email: 'test@example.com'
            }
          }
        end

        it 'returns unauthorized status' do
          post '/api/v1/login', params: invalid_params
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'with malformed request' do
      it 'handles missing user parameter' do
        post '/api/v1/login', params: {}
        expect(response).to have_http_status(:unauthorized)
      end

      it 'handles empty request body' do
        post '/api/v1/login'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/logout' do
    let(:user) { create(:user) }
    let(:token) { JWT.encode(user.jwt_payload, Rails.application.credentials.devise_jwt_secret_key!, 'HS256') }

    context 'with valid JWT token' do
      it 'returns success status' do
        delete '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
      end

      it 'returns success message' do
        delete '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(200)
        expect(json_response['message']).to eq('Logged out successfully.')
      end

      it 'revokes the JWT token' do
        delete '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }

        # The token should be revoked and subsequent requests should fail
        get '/api/v1/me', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid JWT token' do
      it 'returns unauthorized status' do
        delete '/api/v1/logout', headers: { 'Authorization' => 'Bearer invalid_token' }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        delete '/api/v1/logout', headers: { 'Authorization' => 'Bearer invalid_token' }

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(401)
        expect(json_response['message']).to eq("Couldn't find an active session.")
      end
    end

    context 'with missing Authorization header' do
      it 'returns unauthorized status' do
        delete '/api/v1/logout'
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error message' do
        delete '/api/v1/logout'

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq(401)
        expect(json_response['message']).to eq("Couldn't find an active session.")
      end
    end

    context 'with malformed Authorization header' do
      it 'handles missing Bearer prefix' do
        delete '/api/v1/logout', headers: { 'Authorization' => token }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'handles empty token' do
        delete '/api/v1/logout', headers: { 'Authorization' => 'Bearer ' }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
