# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'fileutils'

RSpec.describe Rake::Task, 'smart_goals:backfill_target_dates' do
  before do
    Rails.application.load_tasks unless described_class.task_defined?(task_name)
  end

  let(:task_name) { 'smart_goals:backfill_target_dates' }
  let(:task) { described_class[task_name] }
  let(:batch_size) { '100' }
  let(:dry_run) { 'false' }
  let(:report_path) { Rails.root.join('tmp', 'smart_goal_backfill_task_spec_failures.json').to_s }

  around do |example|
    original_batch_size = ENV.fetch('BATCH_SIZE', nil)
    original_dry_run = ENV.fetch('DRY_RUN', nil)
    original_report_path = ENV.fetch('REPORT_PATH', nil)
    connection = ActiveRecord::Base.connection

    ENV['BATCH_SIZE'] = batch_size
    ENV['DRY_RUN'] = dry_run
    ENV['REPORT_PATH'] = report_path
    connection.change_column_null(:smart_goals, :target_date, true)

    example.run
  ensure
    SmartGoal.where(target_date: nil).delete_all
    connection.change_column_null(:smart_goals, :target_date, false)
    ENV['BATCH_SIZE'] = original_batch_size
    ENV['DRY_RUN'] = original_dry_run
    ENV['REPORT_PATH'] = original_report_path
    FileUtils.rm_f(report_path)
    task.reenable
  end

  it 'backfills target_date from created_at and profile timezone' do
    profile = create(:profile, timezone: 'America/Los_Angeles')
    smart_goal = build(:smart_goal, profile: profile, timeframe: '3_months')
    smart_goal.assign_attributes(
      target_date: nil,
      created_at: Time.utc(2026, 1, 15, 18, 35, 0),
      updated_at: Time.utc(2026, 1, 15, 18, 35, 0)
    )
    smart_goal.save(validate: false)

    task.invoke

    expected = Time.use_zone('America/Los_Angeles') do
      smart_goal.created_at.in_time_zone.beginning_of_day + 3.months
    end
    expect(smart_goal.reload.target_date).to eq(expected)
  end

  it 'reports rows that cannot be backfilled' do
    profile = create(:profile)
    smart_goal = build(:smart_goal, profile: profile, timeframe: 'invalid_timeframe', target_date: nil)
    smart_goal.save(validate: false)

    task.invoke

    expect(smart_goal.reload.target_date).to be_nil
    expect(File).to exist(report_path)
    report = JSON.parse(File.read(report_path))
    expect(report.first['smart_goal_id']).to eq(smart_goal.id)
    expect(report.first['error']).to include('invalid timeframe')
  end

  context 'when DRY_RUN is true' do
    let(:dry_run) { 'true' }

    it 'does not persist updates' do
      profile = create(:profile)
      smart_goal = build(:smart_goal, profile: profile, timeframe: '1_month', target_date: nil)
      smart_goal.save(validate: false)

      task.invoke

      expect(smart_goal.reload.target_date).to be_nil
    end
  end
end
