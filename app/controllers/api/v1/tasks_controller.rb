# frozen_string_literal: true

module Api
  module V1
    # Controller for managing user tasks
    class TasksController < ApplicationController
      TASK_JSON_OPTIONS = { include: { smart_goal: { only: %i[id title] } } }.freeze

      before_action :authenticate_api_v1_user!
      before_action :set_task, only: %i[show update destroy]

      def index
        scope = current_api_v1_profile.tasks.includes(:smart_goal)
        @tasks = params[:completed].present? ? scope.where(completed: params[:completed]) : scope

        render json: @tasks.as_json(TASK_JSON_OPTIONS)
      end

      def show
        render json: @task.as_json(TASK_JSON_OPTIONS)
      end

      def create
        @task = current_api_v1_profile.tasks.build(task_params)
        if @task.save
          render json: @task.as_json(TASK_JSON_OPTIONS), status: :created
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        raise e unless e.message.include?('action_category')

        render json: { errors: ['Action category is not included in the list'] }, status: :unprocessable_entity
      end

      def update
        if @task.update(task_params)
          render json: @task.as_json(TASK_JSON_OPTIONS)
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        raise e unless e.message.include?('action_category')

        render json: { errors: ['Action category is not included in the list'] }, status: :unprocessable_entity
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_task
        @task = current_api_v1_profile.tasks.includes(:smart_goal).find(params[:id])
      end

      def task_params
        params.require(:task).permit(
          :title, :description, :completed, :action_category, :priority, :smart_goal_id, :due_at, :reminder_at
        )
      end
    end
  end
end
