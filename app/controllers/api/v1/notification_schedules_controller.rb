# frozen_string_literal: true

module Api
  module V1
    class NotificationSchedulesController < ApplicationController
      before_action :authenticate_api_v1_user!

      def create
        profile = current_api_v1_profile
        attrs = notification_schedule_params
        kind = attrs[:kind].presence || 'daily_check_in'
        active = attrs.key?(:active) ? attrs[:active] : true

        schedule = nil
        NotificationSchedule.transaction do
          profile.notification_schedules.where(kind: kind, active: true).update_all(active: false) # rubocop:disable Rails/SkipsModelValidations
          schedule = profile.notification_schedules.create!(
            kind: kind,
            local_time: attrs[:local_time],
            timezone: attrs[:timezone],
            active: active
          )
        end

        render json: schedule, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end

      private

      def notification_schedule_params
        params.require(:notification_schedule).permit(:kind, :local_time, :timezone, :active)
      end
    end
  end
end
