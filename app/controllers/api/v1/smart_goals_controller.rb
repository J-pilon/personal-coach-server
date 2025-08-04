# frozen_string_literal: true

module Api
  module V1
    class SmartGoalsController < ApplicationController
      before_action :authenticate_api_v1_user!
      before_action :set_smart_goal, only: %i[update destroy]

      def index
        smart_goals = current_api_v1_profile.smart_goals
        render json: smart_goals
      end

      def create
        smart_goal = current_api_v1_profile.smart_goals.build(smart_goal_params)

        if smart_goal.save
          render json: smart_goal, status: :created
        else
          render json: { errors: smart_goal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @smart_goal.update(smart_goal_params)
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

      def smart_goal_params
        params.require(:smart_goal).permit(
          :title, :description, :timeframe, :specific, :measurable,
          :achievable, :relevant, :time_bound, :completed, :target_date
        )
      end

      def set_smart_goal
        @smart_goal = current_api_v1_profile.smart_goals.find(params[:id])
      end
    end
  end
end
