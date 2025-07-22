# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ai::ContextCompressor do
  let(:user) { create(:user) }
  let(:compressor) { described_class.new(user.id) }

  describe '#compress' do
    context 'when user has goals and tasks' do
      let!(:smart_goal) do
        create(:smart_goal, profile: user.profile,
               title: 'Exercise Daily',
               specific: 'Run 5km every morning',
               timeframe: '3_months')
      end

      let!(:task) do
        create(:task, profile: user.profile,
               title: 'Buy running shoes',
               action_category: 'do',
               completed: false)
      end

      it 'includes recent goals and tasks in context' do
        context = compressor.compress

        expect(context).to include('Current Goals:')
        expect(context).to include('Exercise Daily')
        expect(context).to include('Run 5km every morning')
        expect(context).to include('Recent Tasks:')
        expect(context).to include('Buy running shoes')
      end

      it 'limits goals to MAX_GOALS' do
        create_list(:smart_goal, 5, profile: user.profile, completed: false)

        context = compressor.compress
        goal_count = context.scan(/Goal:/).count

        expect(goal_count).to eq(3) # MAX_GOALS
      end

      it 'limits tasks to MAX_TASKS' do
        create_list(:task, 7, profile: user.profile, completed: false)

        context = compressor.compress
        task_count = context.scan(/Task:/).count

        expect(task_count).to eq(5) # MAX_TASKS
      end

      it 'only includes pending goals' do
        create(:smart_goal, profile: user.profile, completed: true)

        context = compressor.compress
        goal_count = context.scan(/Goal:/).count

        expect(goal_count).to eq(1) # Only the pending goal
      end

      it 'only includes incomplete tasks' do
        create(:task, profile: user.profile, completed: true)

        context = compressor.compress
        task_count = context.scan(/Task:/).count

        expect(task_count).to eq(1) # Only the incomplete task
      end
    end

    context 'when user has no goals or tasks' do
      it 'returns empty context' do
        context = compressor.compress

        expect(context).to eq('')
      end
    end

    context 'when user has only goals' do
      let!(:smart_goal) do
        create(:smart_goal, profile: user.profile,
               title: 'Learn Spanish',
               specific: 'Practice 30 minutes daily')
      end

      it 'includes only goals context' do
        context = compressor.compress

        expect(context).to include('Current Goals:')
        expect(context).to include('Learn Spanish')
        expect(context).not_to include('Recent Tasks:')
      end
    end

    context 'when user has only tasks' do
      let!(:task) do
        create(:task, profile: user.profile,
               title: 'Call mom',
               action_category: 'do')
      end

      it 'includes only tasks context' do
        context = compressor.compress

        expect(context).to include('Recent Tasks:')
        expect(context).to include('Call mom')
        expect(context).not_to include('Current Goals:')
      end
    end

    context 'when context exceeds token limit' do
      before do
        # Create a very long goal title
        long_title = 'A' * 5000
        create(:smart_goal, profile: user.profile, title: long_title)
      end

      it 'truncates context' do
        context = compressor.compress

        expect(context.length).to be <= (described_class::MAX_TOKENS * 4)
        expect(context).to include('[Context truncated for length]')
      end
    end

    context 'when user does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { described_class.new(999999).compress }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
