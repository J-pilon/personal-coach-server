# frozen_string_literal: true

module Api
  module V1
    # Controller for managing user smart goals
    class SmartGoalsController < ApplicationController
      def index
        user = current_user
        smart_goals = user.profile.smart_goals
        render json: smart_goals
      end

      def create
        user = current_user
        smart_goal = user.profile.smart_goals.build(smart_goal_params)

        if smart_goal.save
          render json: smart_goal, status: :created
        else
          render json: { errors: smart_goal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        user = current_user
        smart_goal = user.profile.smart_goals.find(params[:id])

        if smart_goal.update(smart_goal_params)
          render json: smart_goal
        else
          render json: { errors: smart_goal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        user = current_user
        smart_goal = user.profile.smart_goals.find(params[:id])
        smart_goal.destroy
        head :no_content
      end

      private

      def smart_goal_params
        params.require(:smart_goal).permit(
          :title, :description, :timeframe, :specific, :measurable,
          :achievable, :relevant, :time_bound, :completed, :target_date
        )
      end
    end
  end
end
