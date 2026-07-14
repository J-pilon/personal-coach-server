# frozen_string_literal: true

module Api
  module V1
    class HabitsController < ApplicationController
      MAX_HABITS_PER_GOAL = 3

      before_action :authenticate_api_v1_user!

      def create
        smart_goal = current_api_v1_profile.smart_goals.find_by(id: params[:smart_goal_id])
        return render_not_found('SmartGoal not found') unless smart_goal

        habits_params = params.require(:habits)
        if habits_params.length > MAX_HABITS_PER_GOAL
          return render_error('At most 3 habits allowed',
                              :unprocessable_content)
        end

        active_count = smart_goal.habits.active.count
        if active_count + habits_params.length > MAX_HABITS_PER_GOAL
          return render_error('Goal already has the maximum number of habits', :unprocessable_content)
        end

        created = []
        Habit.transaction do
          habits_params.each do |habit_attrs|
            created << smart_goal.habits.create!(
              habit_attributes(habit_attrs).merge(profile: current_api_v1_profile)
            )
          end
        end

        render json: created, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end

      private

      def habit_attributes(habit_attrs)
        habit_attrs.permit(
          :title, :frequency, :cue, :minimum_version, :normal_version, :position,
          frequency_config: {}
        ).to_h
      end

      def render_error(message, status)
        render json: { errors: [message] }, status: status
      end

      def render_not_found(message)
        render json: { error: message }, status: :not_found
      end
    end
  end
end
