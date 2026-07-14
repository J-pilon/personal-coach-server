# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::NotificationSchedules', type: :request do
  let!(:user) { create(:user) }
  let!(:profile) { user.profile }

  before { sign_in user }

  describe 'POST /api/v1/notification_schedules' do
    it 'creates an active daily_check_in schedule' do
      post api_v1_notification_schedules_path,
           params: { local_time: '07:00', timezone: 'America/Los_Angeles' },
           as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include('kind' => 'daily_check_in', 'active' => true)
    end

    it 'deactivates the prior active schedule on upsert' do
      first = create(:notification_schedule, profile: profile, local_time: '08:00', active: true)

      post api_v1_notification_schedules_path,
           params: { local_time: '12:00', timezone: 'UTC' },
           as: :json

      expect(response).to have_http_status(:created)
      expect(first.reload.active).to be(false)
      expect(profile.notification_schedules.where(active: true).count).to eq(1)
    end

    it 'rejects invalid timezone' do
      post api_v1_notification_schedules_path,
           params: { local_time: '07:00', timezone: 'Not/AZone' },
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
