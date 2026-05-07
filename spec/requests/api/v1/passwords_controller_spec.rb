# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Passwords', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe 'POST /api/v1/password' do
    let!(:user) { create(:user, email: 'reset-me@example.com') }

    before { ActionMailer::Base.deliveries.clear }

    context 'when the email is registered' do
      it 'returns 200 and queues a reset instructions email' do
        expect do
          post '/api/v1/password', params: { user: { email: user.email } }
        end.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(response).to have_http_status(:ok)

        delivered = ActionMailer::Base.deliveries.last
        expect(delivered.to).to include(user.email)
        expect(delivered.subject).to match(/reset/i)

        user.reload
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_within(5.seconds).of(Time.current)
      end

      it 'normalizes email casing and whitespace before lookup' do
        expect do
          post '/api/v1/password', params: { user: { email: "  #{user.email.upcase}  " } }
        end.to change { ActionMailer::Base.deliveries.size }.by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the email is not registered' do
      it 'still returns 200 and sends no email (no enumeration)' do
        expect do
          post '/api/v1/password', params: { user: { email: 'nobody@example.com' } }
        end.not_to(change { ActionMailer::Base.deliveries.size })

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig('status', 'message')).to match(/if that email is registered/i)
      end
    end

    context 'when the email is missing' do
      it 'returns 200 and sends no email' do
        expect do
          post '/api/v1/password', params: { user: { email: '' } }
        end.not_to(change { ActionMailer::Base.deliveries.size })

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'PUT /api/v1/password' do
    let(:user) { create(:user, password: 'oldpassword123', password_confirmation: 'oldpassword123') }
    let(:raw_token) { user.send_reset_password_instructions }

    context 'with a valid token and matching password confirmation' do
      it 'resets the password and clears the token' do
        put '/api/v1/password', params: {
          user: {
            reset_password_token: raw_token,
            password: 'newpassword456',
            password_confirmation: 'newpassword456'
          }
        }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig('status', 'message')).to match(/reset successfully/i)

        user.reload
        expect(user.valid_password?('newpassword456')).to be true
        expect(user.valid_password?('oldpassword123')).to be false
        expect(user.reset_password_token).to be_nil
      end
    end

    context 'with an expired token' do
      it 'returns 422 and does not change the password' do
        token = travel_to((Devise.reset_password_within + 1.hour).ago) { user.send_reset_password_instructions }

        put '/api/v1/password', params: {
          user: {
            reset_password_token: token,
            password: 'newpassword456',
            password_confirmation: 'newpassword456'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.dig('status', 'message')).to match(/expired/i)

        user.reload
        expect(user.valid_password?('oldpassword123')).to be true
      end
    end

    context 'with an invalid token' do
      it 'returns 422 and does not change the password' do
        put '/api/v1/password', params: {
          user: {
            reset_password_token: 'totally-bogus-token',
            password: 'newpassword456',
            password_confirmation: 'newpassword456'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.dig('status', 'message')).to match(/invalid/i)

        user.reload
        expect(user.valid_password?('oldpassword123')).to be true
      end
    end

    context 'when password and confirmation do not match' do
      it 'returns 422 and reports the mismatch' do
        put '/api/v1/password', params: {
          user: {
            reset_password_token: raw_token,
            password: 'newpassword456',
            password_confirmation: 'mismatch789'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body.dig('status', 'message')).to match(/confirmation/i)

        user.reload
        expect(user.valid_password?('oldpassword123')).to be true
      end
    end
  end
end
