# frozen_string_literal: true

module Api
  module V1
    class SmartGoalsController < ApplicationController
      MAX_TASKS_PER_SECTION = 50

      before_action :authenticate_api_v1_user!
      before_action :set_smart_goal, only: %i[show update destroy]

      def index
        smart_goals = current_api_v1_profile.smart_goals
        render json: smart_goals
      end

      def show
        render json: @smart_goal.as_json.merge('tasks' => sectioned_tasks(@smart_goal))
      end

      def create
        result = SmartGoals::Create.call(
          profile: current_api_v1_profile,
          params: create_smart_goal_params
        )

        if result.success?
          render json: result.smart_goal, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        if @smart_goal.update(update_smart_goal_params)
          render json: @smart_goal
        else
          render json: { errors: @smart_goal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @smart_goal.destroy
        head :no_content
      end

      private

      def create_smart_goal_params
        params.require(:smart_goal).permit(
          :title, :description, :timeframe, :specific, :measurable,
          :achievable, :relevant, :time_bound, :completed
        )
      end

      def update_smart_goal_params
        params.require(:smart_goal).permit(
          :title, :description, :timeframe, :specific, :measurable,
          :achievable, :relevant, :time_bound, :completed,
          :primary, :why, :target_date
        )
      end

      def set_smart_goal
        @smart_goal = current_api_v1_profile.smart_goals.find(params[:id])
      end

      def sectioned_tasks(smart_goal)
        {
          'open' => smart_goal.tasks.incomplete.order(created_at: :desc).limit(MAX_TASKS_PER_SECTION).as_json,
          'completed' => smart_goal.tasks.completed.order(updated_at: :desc).limit(MAX_TASKS_PER_SECTION).as_json
        }
      end
    end
  end
end
