# frozen_string_literal: true

module SmartGoals
  # Creates a SmartGoal with a server-derived target_date computed from
  # the chosen timeframe and the profile's timezone. Centralizes the
  # "the server owns target_date" rule so controllers never accept a
  # client-supplied value.
  class Create
    TIMEFRAME_TO_MONTHS = {
      '1_month' => 1,
      '3_months' => 3,
      '6_months' => 6
    }.freeze

    Result = Struct.new(:smart_goal, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def self.call(profile:, params:)
      new(profile: profile, params: params).call
    end

    def initialize(profile:, params:)
      @profile = profile
      @params = params
    end

    def call
      smart_goal = @profile.smart_goals.build(@params.merge(target_date: derived_target_date))
      smart_goal.save
      Result.new(smart_goal: smart_goal, errors: smart_goal.errors.full_messages)
    end

    private

    def derived_target_date
      months = TIMEFRAME_TO_MONTHS[@params[:timeframe]]
      return nil unless months

      Time.current.in_time_zone(@profile.timezone).beginning_of_day + months.months
    end
  end
end
