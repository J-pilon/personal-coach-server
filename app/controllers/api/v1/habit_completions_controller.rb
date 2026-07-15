# frozen_string_literal: true

module Api
  module V1
    class HabitCompletionsController < ApplicationController
      before_action :authenticate_api_v1_user!

      def create
        attrs = habit_completion_params
        habit = current_api_v1_profile.habits.find_by(id: attrs[:habit_id])
        return render json: { error: 'Habit not found' }, status: :not_found unless habit

        completed_on = parse_date(attrs[:completed_on]) || Date.current

        completion = habit.habit_completions.find_or_create_by!(completed_on: completed_on) do |c|
          c.state = attrs[:state].presence || 'committed'
          c.committed_at = Time.current
          c.note = attrs[:note] if attrs[:note].present?
        end

        render json: completion, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end

      private

      def habit_completion_params
        params.require(:habit_completion).permit(:habit_id, :completed_on, :state, :note)
      end

      def parse_date(value)
        return nil if value.blank?

        Date.parse(value.to_s)
      rescue Date::Error
        nil
      end
    end
  end
end
