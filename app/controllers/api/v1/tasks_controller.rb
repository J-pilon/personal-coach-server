# frozen_string_literal: true

module Api
  module V1
    # Controller for managing user tasks
    class TasksController < ApplicationController
      before_action :set_task, only: %i[show update destroy]

      def index
        user = current_user
        @tasks = user.profile.tasks
        render json: @tasks
      end

      def show
        render json: @task
      end

      def create
        user = current_user
        @task = user.profile.tasks.build(task_params)
        if @task.save
          render json: @task, status: :created
        else
          render json: @task.errors, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        render json: { errors: ['Invalid action_category value'] }, status: :unprocessable_entity
      end

      def update
        if @task.update(task_params)
          render json: @task
        else
          render json: @task.errors, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        render json: { errors: ['Invalid action_category value'] }, status: :unprocessable_entity
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_task
        user = current_user
        @task = user.profile.tasks.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:title, :description, :completed, :action_category)
      end
    end
  end
end
