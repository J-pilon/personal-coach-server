# frozen_string_literal: true

module Api
  module V1
    class HabitsController < ApplicationController
      MAX_HABITS_PER_GOAL = 3

      before_action :authenticate_api_v1_user!

      def index
        habits = current_api_v1_profile.habits.active.order(:position)
        habits = habits.where(smart_goal_id: params[:smart_goal_id]) if params[:smart_goal_id].present?
        render json: habits
      end

      def create
        smart_goal = current_api_v1_profile.smart_goals.find_by(id: params[:smart_goal_id])
        return render_standard_error(message: 'SmartGoal not found', status: :not_found) unless smart_goal

        habits_params = params.require(:habits)
        if habits_params.length > MAX_HABITS_PER_GOAL
          return render_standard_error(
            message: 'At most 3 habits allowed',
            status: :unprocessable_content
          )
        end

        active_count = smart_goal.habits.active.count
        if active_count + habits_params.length > MAX_HABITS_PER_GOAL
          return render_standard_error(
            message: 'Goal already has the maximum number of habits',
            status: :unprocessable_content
          )
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
        render_validation_error(record: e.record)
      end

      private

      def habit_attributes(habit_attrs)
        habit_attrs.permit(
          :title, :frequency, :cue, :minimum_version, :normal_version, :position,
          frequency_config: {}
        ).to_h
      end
    end
  end
end
