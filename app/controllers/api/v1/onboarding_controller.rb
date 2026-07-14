# frozen_string_literal: true

module Api
  module V1
    class OnboardingController < ApplicationController
      before_action :authenticate_api_v1_user!

      def resume
        profile = current_api_v1_profile

        primary_goal = profile.smart_goals.primary.where(completed: false).order(created_at: :desc).first
        habits = primary_goal ? primary_goal.habits.active.order(:position) : Habit.none
        today_completion = if habits.any?
                             HabitCompletion.where(habit_id: habits.pluck(:id),
                                                   completed_on: Date.current).first
                           end
        active_schedule = profile.notification_schedules.where(kind: 'daily_check_in', active: true).first

        render json: {
          current_step: current_step(profile, primary_goal, habits, today_completion, active_schedule),
          smart_goal_id: primary_goal&.id,
          habit_ids: habits.pluck(:id).presence,
          completion_id: today_completion&.id,
          schedule_id: active_schedule&.id
        }
      end

      private

      def current_step(profile, primary_goal, habits, today_completion, active_schedule)
        return 'complete' if profile.onboarding_completed_at.present?
        return 'profile' if active_schedule
        return 'reminder' if today_completion
        return 'todays_action' if habits.any?
        return 'habits' if primary_goal

        'goal_discovery'
      end
    end
  end
end
