# frozen_string_literal: true

module Api
  module V1
    class HabitsController < ApplicationController
      MAX_HABITS_PER_GOAL = 3
      POSITIONS = (1..MAX_HABITS_PER_GOAL)
      FREQUENCY_ERROR_MESSAGE = 'Frequency must be daily or weekdays'

      before_action :authenticate_api_v1_user!
      before_action :set_active_habit, only: %i[update destroy]

      def index
        habits = current_api_v1_profile.habits.active.order(:position)
        habits = habits.where(smart_goal_id: params[:smart_goal_id]) if params[:smart_goal_id].present?
        render json: habits
      end

      def create
        smart_goal = current_api_v1_profile.smart_goals.find_by(id: params[:smart_goal_id])
        return render_standard_error(message: 'SmartGoal not found', status: :not_found) unless smart_goal

        habits_params = params.require(:habits)
        error = create_precondition_error(smart_goal, habits_params)
        return render_standard_error(**error) if error

        render json: create_habits(smart_goal, habits_params), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_validation_error(record: e.record)
      rescue ActiveRecord::RecordNotUnique
        render_standard_error(message: 'Habit position is already taken', status: :unprocessable_content)
      end

      def update
        attrs = update_attributes
        return render_frequency_error if attrs.key?(:frequency) && !selectable_frequency?(attrs[:frequency])

        if @habit.update(attrs)
          render json: @habit
        else
          render_validation_error(record: @habit)
        end
      end

      def destroy
        @habit.update!(archived_at: Time.current)
        head :no_content
      end

      private

      def set_active_habit
        @habit = current_api_v1_profile.habits.active.find_by(id: params[:id])
        render_standard_error(message: 'Habit not found', status: :not_found) unless @habit
      end

      def create_precondition_error(smart_goal, habits_params)
        if habits_params.length > MAX_HABITS_PER_GOAL
          { message: 'At most 3 habits allowed', status: :unprocessable_content }
        elsif smart_goal.habits.active.count + habits_params.length > MAX_HABITS_PER_GOAL
          { message: 'Goal already has the maximum number of habits', status: :unprocessable_content }
        elsif habits_params.any? { |habit_attrs| !selectable_frequency?(habit_attrs[:frequency]) }
          frequency_error
        end
      end

      def create_habits(smart_goal, habits_params)
        Habit.transaction do
          habits_params.map do |habit_attrs|
            attrs = habit_attributes(habit_attrs)
            attrs[:position] = lowest_free_position(smart_goal) if attrs[:position].blank?
            smart_goal.habits.create!(attrs.merge(profile: current_api_v1_profile))
          end
        end
      end

      def lowest_free_position(smart_goal)
        (POSITIONS.to_a - smart_goal.habits.active.pluck(:position)).first
      end

      def selectable_frequency?(frequency)
        Habit::USER_SELECTABLE_FREQUENCIES.include?(frequency)
      end

      def frequency_error
        {
          message: FREQUENCY_ERROR_MESSAGE,
          status: :unprocessable_content,
          details: { frequency: ['must be daily or weekdays'] }
        }
      end

      def render_frequency_error
        render_standard_error(**frequency_error)
      end

      def habit_attributes(habit_attrs)
        habit_attrs.permit(
          :title, :frequency, :cue, :minimum_version, :normal_version, :position,
          frequency_config: {}
        ).to_h
      end

      def update_attributes
        params.permit(:title, :cue, :minimum_version, :normal_version, :frequency)
      end
    end
  end
end
