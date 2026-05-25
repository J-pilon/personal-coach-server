# frozen_string_literal: true

require 'fileutils'
require 'json'

namespace :smart_goals do
  desc 'Backfill null smart_goals.target_date from timeframe and profile timezone'
  task backfill_target_dates: :environment do
    batch_size = ENV.fetch('BATCH_SIZE', '500').to_i
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'false'))
    report_path = ENV['REPORT_PATH'].presence || default_report_path

    scope = SmartGoal.where(target_date: nil).includes(:profile)
    total = scope.count

    puts "Starting smart goal target_date backfill (rows: #{total}, batch_size: #{batch_size}, dry_run: #{dry_run})"
    next puts 'No rows to backfill.' if total.zero?

    stats = {
      scanned: 0,
      updated: 0,
      failed: 0
    }
    failures = []

    scope.find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |smart_goal|
        stats[:scanned] += 1

        target_date_or_error = derive_target_date(smart_goal)
        if target_date_or_error[:error]
          stats[:failed] += 1
          failures << failure_payload(smart_goal, target_date_or_error[:error])
          next
        end

        if dry_run
          stats[:updated] += 1
          next
        end

        begin
          smart_goal.update(target_date: target_date_or_error[:target_date], updated_at: Time.current)
          stats[:updated] += 1
        rescue StandardError => e
          stats[:failed] += 1
          failures << failure_payload(smart_goal, "failed_to_persist: #{e.message}")
        end
      end
    end

    puts "Backfill complete. scanned=#{stats[:scanned]} updated=#{stats[:updated]} failed=#{stats[:failed]}"

    if failures.any?
      FileUtils.mkdir_p(File.dirname(report_path))
      File.write(report_path, JSON.pretty_generate(failures))
      puts "Failure report written to #{report_path}"
    end
  end

  def derive_target_date(smart_goal)
    months = SmartGoals::Create::TIMEFRAME_TO_MONTHS[smart_goal.timeframe]
    return { error: "invalid timeframe '#{smart_goal.timeframe}'" } unless months

    profile = smart_goal.profile
    return { error: 'missing profile' } unless profile

    timezone = profile.timezone
    return { error: 'missing profile timezone' } if timezone.blank?
    return { error: "invalid profile timezone '#{timezone}'" } unless ActiveSupport::TimeZone[timezone]

    anchor = smart_goal.created_at
    return { error: 'missing created_at' } unless anchor

    target_date = Time.use_zone(timezone) do
      anchor.in_time_zone.beginning_of_day + months.months
    end

    { target_date: target_date }
  end

  def failure_payload(smart_goal, error)
    {
      smart_goal_id: smart_goal.id,
      profile_id: smart_goal.profile_id,
      timeframe: smart_goal.timeframe,
      error: error
    }
  end

  def default_report_path
    Rails.root.join('tmp', "smart_goal_target_date_backfill_failures_#{Time.current.utc.strftime('%Y%m%d%H%M%S')}.json")
  end
end
