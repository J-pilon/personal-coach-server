# frozen_string_literal: true

module Api
  module V1
    # Controller for managing user tasks
    class TasksController < ApplicationController
      before_action :authenticate_api_v1_user!
      before_action :set_task, only: %i[show update destroy]

      def index
        @tasks = if params[:completed].present?
                   current_api_v1_profile.tasks.where(completed: params[:completed])
                 else
                   current_api_v1_profile.tasks
                 end

        render json: @tasks
      end

      def show
        render json: @task
      end

      def create
        @task = current_api_v1_profile.tasks.build(task_params)
        if @task.save
          render json: @task, status: :created
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        raise e unless e.message.include?('action_category')

        render json: { errors: ['Action category is not included in the list'] }, status: :unprocessable_entity
      end

      def update
        if @task.update(task_params)
          render json: @task
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
        @task = current_api_v1_profile.tasks.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:title, :description, :completed, :action_category, :priority)
      end
    end
  end
end
