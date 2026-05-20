# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ApplicationController activity tracking', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  describe 'after_action :touch_profile_activity' do
    context 'when the request is authenticated' do
      before { sign_in user }

      it 'updates last_opened_app_at for the current user profile' do
        profile.notification_preference.update!(last_opened_app_at: nil)

        get api_v1_profile_path(profile)

        expect(response).to have_http_status(:ok)
        expect(profile.notification_preference.reload.last_opened_app_at)
          .to be_within(2.seconds).of(Time.current)
      end

      it 'does not write more often than the throttle window' do
        recent = 1.minute.ago
        profile.notification_preference.update!(last_opened_app_at: recent)

        get api_v1_profile_path(profile)

        expect(profile.notification_preference.reload.last_opened_app_at)
          .to be_within(1.second).of(recent)
      end
    end

    context 'when the request is unauthenticated' do
      it 'does not touch any profile activity' do
        profile.notification_preference.update!(last_opened_app_at: nil)

        get '/up'

        expect(profile.notification_preference.reload.last_opened_app_at).to be_nil
      end
    end
  end
end
