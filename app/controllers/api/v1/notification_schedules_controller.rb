# frozen_string_literal: true

module Api
  module V1
    class NotificationSchedulesController < ApplicationController
      before_action :authenticate_api_v1_user!

      def create
        profile = current_api_v1_profile
        kind = params[:kind].presence || 'daily_check_in'

        schedule = nil
        NotificationSchedule.transaction do
          profile.notification_schedules.where(kind: kind, active: true).update_all(active: false) # rubocop:disable Rails/SkipsModelValidations
          schedule = profile.notification_schedules.create!(
            kind: kind,
            local_time: params[:local_time],
            timezone: params[:timezone],
            active: params.fetch(:active, true)
          )
        end

        render json: schedule, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end
    end
  end
end
